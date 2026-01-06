import 'dart:convert';
import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/main.dart';
import 'package:dua_app/screens/login_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/AppUser.dart';
import '../models/Comment.dart';
import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  static const String baseUrl = "https://duarequests.app/api";

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // State
  AppUser? _currentUser;
  String? _cachedToken; // ✅ Optimization: Cache token in memory
  static String? _appVersion;

  AppUser? get currentUser => _currentUser;

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  static Future<void> initAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      debugPrint("App Version: $_appVersion");
    } catch (e) {
      _appVersion = "1.0.0";
    }
  }

  Future<AppUser?> getStoredUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token'); // Load token into memory
    final String? data = prefs.getString('user_data');

    if (data != null) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(data));
        return _currentUser;
      } catch (e) {
        await prefs.remove('user_data');
      }
    }
    return null;
  }

  // ==========================================================
  // CORE HTTP ENGINE (Optimized)
  // ==========================================================

  /// Unified Request Handler
  Future<http.Response> _request(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
      }) async {
    // 1. Ensure Token is loaded
    if (requiresAuth && _cachedToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
    }

    // 2. Get AppCheck (Fail silent)
    String? appCheckToken;
    try {
      appCheckToken = await FirebaseAppCheck.instance.getToken(false);
    } catch (_) {}

    // 3. Build Headers
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'App-Version': _appVersion ?? '1.0.0',
      if (requiresAuth && _cachedToken != null)
        'Authorization': 'Bearer $_cachedToken',
      if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
      if (!requiresAuth) 'X-App-Key': dotenv.env['APP_KEY'] ?? '',
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    http.Response response;

    // 4. Execute
    try {
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        response = await http.get(uri, headers: headers);
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }

    // 5. Global Check (Banned/Auth)
    await _handleGlobalErrors(response);

    return response;
  }

  Future<void> _handleGlobalErrors(http.Response response) async {
    if (response.statusCode == 403) {
      // Logic for Banned Users
      try {
        final body = jsonDecode(response.body);
        if (body['message'].toString().toLowerCase().contains('banned')) {
          await _performLogoutCleanUp();
          _showBanDialog();
        }
      } catch (_) {}
    }
  }

  Future<void> _performLogoutCleanUp() async {
    _currentUser = null;
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _showBanDialog() {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.accountBannedTitle ?? "Account Banned", style: const TextStyle(color: Colors.red)),
          content: Text(l10n?.accountBannedMessage ?? "Your account has been banned."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (c) => const LoginScreen()),
                      (route) => false,
                );
              },
              child: Text(l10n?.ok ?? "OK"),
            ),
          ],
        ),
      );
    }
  }

  // ✅ Helper to extract cursor safely
  String? _parseNextCursor(Map<String, dynamic> json) {
    if (json['next_cursor'] != null) return json['next_cursor'];
    if (json['meta'] != null && json['meta']['next_cursor'] != null) {
      return json['meta']['next_cursor'];
    }
    if (json['next_page_url'] != null) {
      return Uri.parse(json['next_page_url']).queryParameters['cursor'];
    }
    return null;
  }

  // ==========================================================
  // AUTH METHODS
  // ==========================================================

  Future<String?> login(String email, String password) async {
    try {
      final uuid = await _getDeviceUuid();
      final response = await _request('POST', '/auth/login', body: {
        'email': email,
        'password': password,
        'device_uuid': uuid,
        'device_name': 'mobile_app',
      }, requiresAuth: false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _handleAuthSuccess(data);
        return null; // Success
      }
      return data['message'] ?? "Login failed";
    } catch (_) {
      return "Connection error";
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final uuid = await _getDeviceUuid();
      final response = await _request('POST', '/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'device_name': 'mobile_app',
        'device_uuid': uuid,
      }, requiresAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _handleAuthSuccess(jsonDecode(response.body));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) return prefs.getString('auth_token');

    final uuid = await _getDeviceUuid();
    // Retrieve or set guest UUID
    String guestUuid = prefs.getString('guest_uuid') ?? uuid;

    try {
      final response = await _request('POST', '/auth/guest', body: {
        'device_uuid': guestUuid
      }, requiresAuth: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _handleAuthSuccess(data);
        return data['token'];
      }
    } catch (e) {
      debugPrint("Guest Login Error: $e");
    }
    return null;
  }

  Future<String?> loginWithGoogle() async {
    const webClientId = "742894756114-53auc51llpq4g54gh3sct2hat0ir1j3k.apps.googleusercontent.com";
    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId, scopes: ['email', 'profile', 'openid']);

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "Login cancelled";

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) return "Failed to get ID Token";

      return await _socialLoginBackend('google', idToken, googleAuth.accessToken);
    } catch (e) {
      return "Google Login failed: $e";
    }
  }

  Future<String?> _socialLoginBackend(String provider, String token, String? accessToken) async {
    try {
      final uuid = await _getDeviceUuid();
      final response = await _request('POST', '/auth/social-login', body: {
        'provider': provider,
        'token': token,
        'access_token': accessToken,
        'device_uuid': uuid,
        'device_name': 'mobile_app',
      }, requiresAuth: false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _handleAuthSuccess(data);
        return null;
      }
      return data['message'] ?? "Social login failed";
    } catch (_) {
      return "Connection error";
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'];
    _cachedToken = token; // Update Memory
    await prefs.setString('auth_token', token);

    if (data['user'] != null) {
      _currentUser = AppUser.fromJson(data['user']); // Update Memory
      await prefs.setString('user_data', jsonEncode(data['user']));
    }
    _syncFcmToken();
  }

  Future<void> logout() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}

    // Call backend
    if (_cachedToken != null) {
      try {
        await _request('POST', '/auth/logout', body: {'fcm_token': fcmToken});
      } catch (_) {}
    }

    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _performLogoutCleanUp();
  }

  Future<bool> deleteAccount(String password) async {
    try {
      final response = await _request('POST', '/auth/delete-account', body: {'password': password});
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // DATA METHODS (Feed, Posts, Comments)
  // ==========================================================

  Future<Map<String, dynamic>> getFeed({int? userId, int? categoryId, String? cursor}) async {
    String url = '/posts?';
    if (cursor != null) url += 'cursor=$cursor&';
    if (userId != null) url += 'app_user_id=$userId&';
    if (categoryId != null) url += 'category_id=$categoryId&';

    final response = await _request('GET', url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'posts': (json['data'] as List).map((e) => Post.fromJson(e)).toList(),
        'next_cursor': _parseNextCursor(json),
      };
    }
    throw Exception('Failed to load feed');
  }

  Future<Map<String, dynamic>> getComments(int postId, {String? nextCursor, int? commentId}) async {
    String url = '/posts/$postId/comments?';
    if (nextCursor != null) url += 'cursor=$nextCursor&';
    if (commentId != null) url += 'comment_id=$commentId&';

    final response = await _request('GET', url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'comments': (json['data'] as List).map((e) => Comment.fromJson(e)).toList(),
        'next_cursor': _parseNextCursor(json),
      };
    }
    throw Exception('Failed to load comments');
  }

  Future<Post> getPostById(int id) async {
    final response = await _request('GET', '/posts/$id');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Post.fromJson(json['data'] ?? json);
    }
    throw Exception('Failed to load post');
  }

  Future<bool> createPost(String content, int categoryId, bool isAnonymous) async {
    final response = await _request('POST', '/posts', body: {
      'content': content,
      'category_id': categoryId,
      'is_anonymous': isAnonymous,
    });
    return response.statusCode == 201;
  }

  Future<bool> postComment(int postId, String content) async {
    final response = await _request('POST', '/posts/$postId/comments', body: {'content': content});
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> toggleLike(int postId) async {
    final response = await _request('POST', '/posts/$postId/like', body: {});
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<bool> deletePost(int postId) async {
    final response = await _request('DELETE', '/posts/$postId');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteComment(int commentId) async {
    final response = await _request('DELETE', '/comments/$commentId');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<Category>> getCategories() async {
    final response = await _request('GET', '/categories');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<AppUser> getUserProfile() async {
    final response = await _request('GET', '/user');
    if (response.statusCode == 200) return AppUser.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load profile');
  }

  Future<AppUser> getUserById(int id) async {
    final response = await _request('GET', '/users/$id');
    if (response.statusCode == 200) return AppUser.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load user');
  }

  Future<String?> translateContent({required int id, required String type, required String targetLang}) async {
    try {
      final response = await _request('POST', '/translate', body: {
        'id': id, 'type': type, 'target_lang': targetLang,
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['translation'];
      }
    } catch (_) {}
    return null;
  }

  Future<bool> reportContent({required String type, required int id, required String reason, String? details}) async {
    final response = await _request('POST', '/report', body: {
      'type': type, 'id': id, 'reason': reason, 'details': details,
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword, required String newPasswordConfirmation}) async {
    try {
      final response = await _request('POST', '/auth/change-password', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Changed successfully'};
      } else {
        String msg = data['message'] ?? 'Failed';
        if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors['current_password'] != null) msg = errors['current_password'][0];
          else if (errors['new_password'] != null) msg = errors['new_password'][0];
        }
        return {'success': false, 'message': msg};
      }
    } catch (_) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ==========================================================
  // UTILS
  // ==========================================================

  Future<void> _syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) updateDeviceToken(token);
    } catch (_) {}
  }

  Future<void> updateDeviceToken(String token, {String? languageCode}) async {
    try {
      String finalLanguage = languageCode ?? Platform.localeName.split('_')[0];
      if (languageCode == null) {
        final prefs = await SharedPreferences.getInstance();
        finalLanguage = prefs.getString('language_code') ?? finalLanguage;
      }

      await _request('POST', '/user/device-token', body: {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'language_code': finalLanguage,
      });
    } catch (_) {}
  }

  Future<String> _getDeviceUuid() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return (await deviceInfo.androidInfo).id;
    } else if (Platform.isIOS) {
      return (await deviceInfo.iosInfo).identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }
}