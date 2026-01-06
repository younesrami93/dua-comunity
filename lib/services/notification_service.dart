import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Access to navigatorKey
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../models/post.dart';
import '../api/api_service.dart';

// ✅ Background Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ✅ NEW: Variable to store data if the app hasn't started yet
  Map<String, dynamic>? _pendingNotificationData;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // 2. Setup Local Notifications
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

      // 3. Get Device Token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // ApiService().updateDeviceToken(token); // Call this if needed
      }

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 5. Handle Background/Terminated Clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageAction(message.data);
      });

      // 6. Check if app was opened from a terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          print("Found initial message (Terminated state): ${message.data}");
          _handleMessageAction(message.data);
        }
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  // ✅ NEW: Call this from main.dart after the app builds
  void checkPendingNotification() {
    if (_pendingNotificationData != null) {
      if (navigatorKey.currentContext == null) {
        print("Context is still null in checkPendingNotification. Retrying...");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkPendingNotification();
        });
        return;
      }

      print("Processing pending notification...");
      _handleMessageAction(_pendingNotificationData!);
      _pendingNotificationData = null; // Clear it after handling
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
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageAction(Map<String, dynamic> data) async {
    // ✅ CRITICAL FIX: If Context is null, store data for later
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Context is null, queuing notification action...");
      _pendingNotificationData = data;
      return;
    }

    final String? type = data['type'];
    // Safely convert ID to String (handles int/String differences in payloads)
    final String? idString = data['id']?.toString();

    print("Handling Notification Action: Type=$type, ID=$idString");

    if (idString == null) return;

    if (type == 'post_details' || type == 'post' || type == 'comment') {
      try {
        final int postId = int.parse(idString);

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        // Fetch Post
        final Post post = await ApiService().getPostById(postId);

        // Close loading
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Navigate
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            ),
          );
        }
      } catch (e) {
        // Ensure loading dialog is closed if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        print("Error opening post: $e");
      }
    } else if (type == 'profile') {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: int.tryParse(idString ?? '0'))),
        );
      }
    }
  }
}