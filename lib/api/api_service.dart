import 'dart:convert';
import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/main.dart'; // Ensure this imports your global navigatorKey
import 'package:dua_app/screens/login_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/AppUser.dart';
import '../models/Comment.dart';
import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  // ⚠️ REPLACE WITH YOUR ACTUAL API URL (Use HTTPS for production)
  static const String baseUrl = "https://duarequests.app/api";

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  // ==========================================================
  // ✅ GLOBAL BANNED HANDLER & REQUEST HELPERS
  // ==========================================================

  Future<String?> _getAppCheckToken() async {
    try {
      // Force refresh only if necessary; usually false is fine
      final token = await FirebaseAppCheck.instance.getToken(false);
      return token;
    } catch (e) {
      print("App Check Token Error: $e");
      return null;
    }
  }

  Future<void> _saveUserLocally(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = user;
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<AppUser?> getStoredUser() async {
    // 1. Check Memory (Fastest)
    if (_currentUser != null) {
      return _currentUser;
    }

    // 2. Check Disk (If app just restarted)
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_data');

    print("Checking disk for user data ${data}");

    if (data != null) {
      try {
        // Load into memory for next time
        _currentUser = AppUser.fromJson(jsonDecode(data));
        print("user is instantiated from prefs ${_currentUser?.username}");

        return _currentUser;
      } catch (e) {
        print("Error parsing stored user: $e");
        await prefs.remove('user_data'); // Corrupt data, clear it
      }
    } else {
      print("user data is null, it was not save");
    }

    return null;
  }

  Future<void> _handleResponseCheck(http.Response response) async {
    // Check for 403 Forbidden specifically
    if (response.statusCode == 403) {
      bool isBanned = false;
      try {
        final body = jsonDecode(response.body);
        // Check if the message mentions "banned"
        if (body['message'] != null &&
            body['message'].toString().toLowerCase().contains('banned')) {
          isBanned = true;
        }
      } catch (_) {}

      if (isBanned) {
        // 1. Clear Data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 2. Show Modal & Redirect (Using Global Key)
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          // ✅ Get Localizations
          final l10n = AppLocalizations.of(context);

          showDialog(
            context: context,
            barrierDismissible: false, // User MUST click OK
            builder: (ctx) => AlertDialog(
              title: Text(
                l10n?.accountBannedTitle ?? "Account Banned",
                style: const TextStyle(color: Colors.red),
              ),
              content: Text(
                l10n?.accountBannedMessage ??
                    "Your account has been banned due to policy violations. You will be logged out.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close Dialog
                    // Redirect to Login and remove all history
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    l10n?.ok ?? "OK",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  // 1. Authenticated GET Wrapper
  Future<http.Response> _get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final appCheckToken = await _getAppCheckToken();

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
      },
    );

    await _handleResponseCheck(response); // Global Ban Check
    return response;
  }

  // 2. Authenticated POST Wrapper
  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final appCheckToken = await _getAppCheckToken();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
      },
      body: jsonEncode(body),
    );

    await _handleResponseCheck(response); // Global Ban Check
    return response;
  }

  // ==========================================================
  // PUBLIC METHODS
  // ==========================================================

  // 1. Guest Login
  Future<String?> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) {
      return prefs.getString('auth_token');
    }

    final uuid = await _getDeviceUuid();

    // Check if we have a stored guest UUID to reuse (optional feature)
    String? guestUuid = prefs.getString('guest_uuid');
    if (guestUuid == null) {
      // guestUuid = const Uuid().v4();
      // await prefs.setString('guest_uuid', guestUuid);
      guestUuid = uuid; // Fallback to device ID for now
    }

    final appCheckToken = await _getAppCheckToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/guest'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
          'X-App-Key': dotenv.env['APP_KEY'] ?? '',
        },
        body: jsonEncode({'device_uuid': guestUuid}),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];
        await prefs.setString('auth_token', token);

        if (data['user'] != null) {
          await _saveUserLocally(AppUser.fromJson(data['user']));
        } else {
          print("user is null, cant save it");
        }

        return token;
      }
    } catch (e) {
      print("Guest Login Error: $e");
    }
    return null;
  }

  // 2. Fetch Feedapi_service
  Future<Map<String, dynamic>> getFeed({
    int? userId,
    int? categoryId,
    String? cursor, // ✅ Accept cursor instead of page
  }) async {
    String url = '/posts?';
    if (cursor != null) url += 'cursor=$cursor&'; // ✅ Send cursor to backend
    if (userId != null) url += 'app_user_id=$userId&';
    if (categoryId != null) url += 'category_id=$categoryId&';

    print(url);

    final response = await _get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];

      // ✅ Extract the Next Cursor safely
      String? nextCursor;
      if (json['next_cursor'] != null) {
        nextCursor = json['next_cursor'];
      } else if (json['meta'] != null && json['meta']['next_cursor'] != null) {
        nextCursor = json['meta']['next_cursor'];
      } else if (json['next_page_url'] != null) {
        // Fallback: Extract from URL if needed
        final uri = Uri.parse(json['next_page_url']);
        nextCursor = uri.queryParameters['cursor'];
      }

      return {
        'posts': data.map((e) => Post.fromJson(e)).toList(),
        'next_cursor': nextCursor, // ✅ Return it
      };
    } else {
      throw Exception('Failed to load feed');
    }
  }

  // 3. Get Comments
  Future<Map<String, dynamic>> getComments(
    int postId, {
    String? nextCursor,
  }) async {
    String url = '/posts/$postId/comments';
    if (nextCursor != null) url += '?cursor=$nextCursor';

    final response = await _get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];

      String? next;
      if (json['next_cursor'] != null) {
        next = json['next_cursor'];
      } else if (json['meta'] != null && json['meta']['next_cursor'] != null) {
        next = json['meta']['next_cursor'];
      } else if (json['next_page_url'] != null) {
        final uri = Uri.parse(json['next_page_url']);
        next = uri.queryParameters['cursor'];
      }

      return {
        'comments': data.map((e) => Comment.fromJson(e)).toList(),
        'next_cursor': next,
      };
    } else {
      throw Exception('Failed to load comments');
    }
  }

  // 4. Post a Comment
  Future<bool> postComment(int postId, String content) async {
    final response = await _post('/posts/$postId/comments', {
      'content': content,
    });
    print(response.body);
    return response.statusCode == 201;
  }

  // 5. Get List of Categories
  Future<List<Category>> getCategories() async {
    final response = await _get('/categories');
    print(response.body);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // 6. Create a new Post
  Future<bool> createPost(
    String content,
    int categoryId,
    bool isAnonymous,
  ) async {
    final response = await _post('/posts', {
      'content': content,
      'category_id': categoryId,
      'is_anonymous': isAnonymous,
    });
    return response.statusCode == 201;
  }

  // 7. Toggle Like
  Future<Map<String, dynamic>?> toggleLike(int postId) async {
    final response = await _post('/posts/$postId/like', {});

    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // 8. Get Current User Profile
  Future<AppUser> getUserProfile() async {
    final response = await _get('/user');

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // 9. Get Specific User by ID
  Future<AppUser> getUserById(int id) async {
    final response = await _get('/users/$id');

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // 10. Report Content
  Future<bool> reportContent({
    required String type,
    required int id,
    required String reason,
    String? details,
  }) async {
    final response = await _post('/report', {
      'type': type,
      'id': id,
      'reason': reason,
      'details': details,
    });

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 11. Delete Account
  Future<bool> deleteAccount(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final appCheckToken = await _getAppCheckToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Required for body
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
        body: jsonEncode({'password': password}),
      );

      await _handleResponseCheck(response);
      print("delete account response ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Account Error: $e");
      return false;
    }
  }

  // 12. Secure Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final fcmToken = await FirebaseMessaging.instance.getToken();

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    if (token == null) return;

    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print("Error signing out of Google: $e");
    }
    final appCheckToken = await _getAppCheckToken();

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );
    } catch (_) {}
  }

  // ==========================================================
  // AUTH (Login/Register)
  // ==========================================================

  Future<String> _getDeviceUuid() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }

  // Login: Returns NULL if success, String Message if error
  Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = await _getDeviceUuid();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': dotenv.env['APP_KEY'] ?? '',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_uuid': uuid,
          'device_name': 'mobile_app',
        }),
      );

      final data = jsonDecode(response.body);

      print(response.body);
      if (response.statusCode == 200) {
        String token = data['token'];
        await prefs.setString('auth_token', token);

        if (data['user'] != null) {
          await _saveUserLocally(AppUser.fromJson(data['user']));
        } else {
          print("user is null, cant save it");
        }
        print("login success");

        _syncFcmToken();

        return null; // ✅ Success
      } else {
        // Return the specific error from backend, or fallback to localized generic error
        final context = navigatorKey.currentContext;
        final fallback = context != null
            ? AppLocalizations.of(context)?.loginFailed
            : "Login failed";

        return data['message'] ?? fallback;
      }
    } catch (e) {
      final context = navigatorKey.currentContext;
      return context != null
          ? AppLocalizations.of(context)?.connectionError
          : "Connection error. Please check your internet.";
    }
  }

  Future<bool> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = await _getDeviceUuid();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': dotenv.env['APP_KEY'] ?? '',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'device_name': 'mobile_app',
          'device_uuid': uuid,
        }),
      );

      print("response body${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await prefs.setString('auth_token', data['token']);

        if (data['user'] != null) {
          await _saveUserLocally(AppUser.fromJson(data['user']));
        }

        _syncFcmToken();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> translateContent({
    required int id,
    required String type, // 'post' or 'comment'
    required String targetLang,
  }) async {
    try {
      print("translating ${id} , type ${type} , targetLang ${targetLang}");

      final response = await _post('/translate', {
        'id': id,
        'type': type,
        'target_lang': targetLang,
      });

      if (response.statusCode == 200) {
        print("response code 200");
        print(response);
        print(response.body);
        final data = jsonDecode(response.body);
        print("response data ${data['translation']}");
        return data['translation'];
      }
      print("response code ${response.statusCode}");
      // print response as json
      print(response.body);
    } catch (e) {
      print("Translation error: $e");
    }
    return null;
  }

  // 14. Delete Comment
  Future<bool> deleteComment(int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final appCheckToken = await _getAppCheckToken();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        // Assumes standard REST route
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
      );
      print(response.body);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Comment Error: $e");
      return false;
    }
  }

  // 15. Delete Post
  Future<bool> deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final appCheckToken = await _getAppCheckToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
      );
      print(response.body);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Post Error: $e");
      return false;
    }
  }

  // ==========================================================
  // SOCIAL AUTH
  // ==========================================================

  Future<String?> loginWithGoogle() async {
    // 1. Initialize Google Sign In
    // IMPORTANT: We use the "Web Client ID" here so Google generates a token
    // that our Laravel Backend (which is a "Web" app to Google) can verify.
    const String webClientId =
        "742894756114-53auc51llpq4g54gh3sct2hat0ir1j3k.apps.googleusercontent.com";

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile', 'openid'],
    );

    try {
      // 2. Trigger the Native Login Dialog
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return "Login cancelled"; // User closed the popup
      }

      // 3. Get the Auth Details (Tokens)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // This is the token Laravel needs to verify the user
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return "Failed to get ID Token from Google";
      }

      // 4. Send to Laravel
      return await _socialLoginBackend(
        provider: 'google',
        token: idToken,
        accessToken: accessToken, // Send this too just in case needed
      );
    } catch (e) {
      print("Google Sign In Error: $e");
      return "Google Login failed: $e";
    }
  }

  // Helper function to talk to Laravel
  Future<String?> _socialLoginBackend({
    required String provider,
    required String token,
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = await _getDeviceUuid();

    final appCheckToken = await _getAppCheckToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/social-login'),
        // You need to create this in Laravel
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
          'X-App-Key': dotenv.env['APP_KEY'] ?? '',
        },
        body: jsonEncode({
          'provider': provider, // 'google'
          'token': token, // The ID Token
          'access_token': accessToken,
          'device_uuid': uuid,
          'device_name': 'mobile_app',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login Success
        await prefs.setString('auth_token', data['token']);
        if (data['user'] != null) {
          await _saveUserLocally(AppUser.fromJson(data['user']));
        }
        _syncFcmToken();
        return null; // Null means success in your app logic
      } else {
        return data['message'] ?? "Social login failed";
      }
    } catch (e) {
      return "Connection error";
    }
  }

  // 16. Change Password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final appCheckToken = await _getAppCheckToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        // Handle validation errors or bad request
        String errorMessage = data['message'] ?? 'Failed to change password';

        // Optional: specific Laravel validation errors
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.containsKey('current_password')) {
            errorMessage = errors['current_password'][0];
          } else if (errors.containsKey('new_password')) {
            errorMessage = errors['new_password'][0];
          }
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  // ==========================================================
  // ✅ NEW: FCM TOKEN MANAGER
  // ==========================================================

  Future<void> _syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        updateDeviceToken(token);
      }
    } catch (e) {
      print("Error syncing FCM Token: $e");
    }
  }

  Future<void> updateDeviceToken(String token, {String? languageCode}) async {
    try {
      String finalLanguage;

      if (languageCode != null) {
        // 1. Use the one passed explicitly (if available)
        finalLanguage = languageCode;
      } else {
        // 2. Try to get it from SharedPreferences (User's manual selection)
        final prefs = await SharedPreferences.getInstance();
        // Assuming you save the language with key 'language_code' in your settings
        final savedLang = prefs.getString('language_code');

        if (savedLang != null) {
          finalLanguage = savedLang;
        } else {
          // 3. Fallback: Get the Device's System Language (e.g., 'en_US' -> 'en')
          // explicitly import 'dart:io' for Platform
          finalLanguage = Platform.localeName.split('_')[0];
        }
      }

      final response = await _post('/user/device-token', {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'language_code': finalLanguage, // ✅ Sending it to Laravel
      });

      print("Device Token Updated [$finalLanguage]: $response");
    } catch (e) {
      print("Failed to update token: $e");
    }
  }


  Future<Post> getPostById(int id) async {
    final response = await _get('/posts/$id');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Handles both cases: if Laravel wraps it in 'data' or returns directly
      final postData = json['data'] ?? json;
      return Post.fromJson(postData);
    } else {
      throw Exception('Failed to load post');
    }
  }
}
