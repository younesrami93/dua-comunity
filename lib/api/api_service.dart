import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/AppUser.dart';
import '../models/Comment.dart';
import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  // ⚠️ REPLACE WITH YOUR PC IP
  static const String baseUrl = "http://192.168.0.138:8000/api";

  // Singleton pattern (Optional, but good practice)
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  // 1. Guest Login (The logic you saw earlier)
  Future<String?> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    // Return token if we already have it
    if (prefs.containsKey('auth_token')) {
      return prefs.getString('auth_token');
    }

    // Otherwise, generate UUID and register
    final deviceInfo = DeviceInfoPlugin();
    String uuid = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      uuid = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      uuid = iosInfo.identifierForVendor ?? 'unknown_ios';
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_uuid': uuid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];
        await prefs.setString('auth_token', token);
        return token;
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  // 2. Fetch Feed
  Future<List<Post>> getFeed({int? userId, int? categoryId}) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String url = '$baseUrl/posts?';
    if (userId != null) {
      url += 'app_user_id=$userId&';
    }

    if (categoryId != null) { // <--- Add logic
      url += 'category_id=$categoryId&';
    }
    if (kDebugMode) {
      print(url);
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token', // Send the token!
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data']; // Laravel pagination puts list in "data"
      return data.map((e) => Post.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load feed');
    }
  }

  // 3. Get Comments (Updated for Pagination)
  // Returns a Map with the list and the 'next_cursor' for the next page
  Future<Map<String, dynamic>> getComments(
    int postId, {
    String? nextCursor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    String url = '$baseUrl/posts/$postId/comments';
    if (nextCursor != null) {
      url += '?cursor=$nextCursor';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (kDebugMode) {
      print("DEBUG: API Response Code: ${response.statusCode}");
      print("DEBUG: API Body: ${response.body}");
      print("DEBUG: API Headers: ${response.headers}");
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];

      // ✅ FIX: Safely try to find the cursor, or default to null
      String? next;

      // Option A: Laravel puts it in 'next_cursor' at root
      if (json['next_cursor'] != null) {
        next = json['next_cursor'];
      }
      // Option B: Laravel puts it in 'meta' -> 'next_cursor'
      else if (json['meta'] != null && json['meta']['next_cursor'] != null) {
        next = json['meta']['next_cursor'];
      }
      // Option C: Parse from next_page_url (fallback)
      else if (json['next_page_url'] != null) {
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        // We can add 'parent_id' here later for replies
      }),
    );

    return response.statusCode == 201;
  }

  // 5. Get List of Categories
  Future<List<Category>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // 6. Create a new Dua
  Future<bool> createPost(
    String content,
    int categoryId,
    bool isAnonymous,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        'category_id': categoryId,
        'is_anonymous': isAnonymous,
      }),
    );

    return response.statusCode == 201;
  }

  // 7. Toggle Like
  Future<Map<String, dynamic>?> toggleLike(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
        // Returns: { "message": "Liked", "likes_count": 5, "liked": true }
      }
    } catch (e) {
      print("Like Error: $e");
    }
    return null;
  }

  // 8. Get Current User Profile
  Future<AppUser> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/user'), // Standard Sanctum endpoint
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // 9. Get Specific User by ID
  Future<AppUser> getUserById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }
}
