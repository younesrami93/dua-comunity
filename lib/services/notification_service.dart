import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Access to navigatorKey
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../models/post.dart';
import '../api/api_service.dart';

// ✅ Background Handler (Must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // 2. Setup Local Notifications (For foreground alerts)
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            _handleMessageAction(jsonDecode(response.payload!));
          }
        },
      );

      // 3. Get Device Token & Send to Backend
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("FCM Token: $token");
        // TODO: Send this token to your Laravel Backend via ApiService
        ApiService().updateDeviceToken(token);
      }

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 5. Handle Background/Terminated Clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageAction(message.data);
      });

      // Check if app was opened from a terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageAction(message.data);
        }
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data), // Pass data to click handler
      );
    }
  }

  // ✅ THIS IS WHERE THE MAGIC HAPPENS (The "Actions")
  void _handleMessageAction(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final String? type = data['type']; // e.g., 'post', 'comment', 'profile'
    final String? id = data['id'];

    if (type == 'post' || type == 'comment') {
      // Fetch the full post before opening (since we only have ID)
      // You might need to add getPostById to your ApiService
      try {
        // Show loading dialog?
        // Navigate
        // Note: For now, we assume we fetch it or pass simple data
        // For a real app, usually you fetch the single post from API here.

        // Example:
        // final post = await ApiService().getPostById(int.parse(id!));
        // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
      } catch (e) {
        print("Error opening post: $e");
      }
    } else if (type == 'profile') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: int.tryParse(id ?? '0'))));
    }
  }
}