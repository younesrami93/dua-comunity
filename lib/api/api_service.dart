import 'dart:convert';
import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/main.dart'; // Ensure this imports your global navigatorKey
import 'package:dua_app/screens/login_screen.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
// ✅ Import generated localizations

import '../models/AppUser.dart';
import '../models/Comment.dart';
import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  // ⚠️ REPLACE WITH YOUR ACTUAL API URL (Use HTTPS for production)
  static const String baseUrl = "https://morocode.com/dua/public/api";
  static const String app_key = "my_super_secret_key_123";

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  // ==========================================================
  // ✅ GLOBAL BANNED HANDLER & REQUEST HELPERS
  // ==========================================================

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

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/guest'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': app_key,
        },
        body: jsonEncode({'device_uuid': guestUuid}),
      );

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

  // 2. Fetch Feed
  Future<List<Post>> getFeed({int? userId, int? categoryId}) async {
    String url = '/posts?';
    if (userId != null) url += 'app_user_id=$userId&';
    if (categoryId != null) url += 'category_id=$categoryId&';

    final response = await _get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Post.fromJson(e)).toList();
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Required for body
          'Accept': 'application/json',
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

    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
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
          'X-App-Key': app_key,
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
        }else{
          print("user is null, cant save it");
        }
        print("login success");


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
          'X-App-Key': app_key,
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

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'), // Assumes standard REST route
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

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
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Post Error: $e");
      return false;
    }
  }

}
