import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../models/post.dart';
import '../api/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message: ${message.messageId}");

  if (message.data.isNotEmpty) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pending_notification_data',
      jsonEncode(message.data),
    );
    print("Saved pending data to disk (Nuclear Option) : ${message.data}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );

  // Variable to store data if the app hasn't started yet
  Map<String, dynamic>? _pendingNotificationData;

  Map<String, dynamic>? get pendingData => _pendingNotificationData;

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
        // ApiService().updateDeviceToken(token);
      }


      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 5. Handle Background/Terminated Clicks (FCM)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageAction(message.data);
      });

      // 6. Check if app was opened from a terminated state (FCM)
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          print("Found initial message (Terminated FCM): ${message.data}");
          _handleMessageAction(message.data);
        }
      });

      // ✅ 7. NEW: Check if app was opened from a terminated state (LOCAL NOTIFICATION)
      // This fixes the "Open -> Close App -> Click Notification" bug
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await _localNotifications.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final notificationResponse =
            notificationAppLaunchDetails!.notificationResponse;

        if (notificationResponse?.payload != null) {
          print("Found initial message (Terminated Local): ${notificationResponse!.payload}");
          _handleMessageAction(jsonDecode(notificationResponse.payload!));
        }
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _setupLocalNotifications() async {
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

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  // Called from main.dart after the first frame
  void checkPendingNotification() {
    if (_pendingNotificationData != null) {
      print("Processing pending notification from cold start...");
      _handleMessageAction(_pendingNotificationData!);
      _pendingNotificationData = null;
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && Platform.isAndroid) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageAction(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;

    // If context is null (app launching) or unmounted, save data for later
    if (context == null || !context.mounted) {
      print("Context is null, queuing notification action for later...");
      _pendingNotificationData = data;
      return;
    }

    final String? type = data['type'];
    final String? idString = data['id'];

    int? targetCommentId;
    if (data['comment_id'] != null) {
      targetCommentId = int.tryParse(data['comment_id'].toString());
    }

    if (idString == null) return;

    if (type == 'post_details' || type == 'post' || type == 'comment') {
      try {
        final int postId = int.parse(idString);

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        final Post post = await ApiService().getPostById(postId);

        // Close loading dialog
        if (Navigator.canPop(context)) Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: post,
              highlightCommentId: targetCommentId,
            ),
          ),
        );
      } catch (e) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        print("Error opening post: $e");
      }
    } else if (type == 'profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: int.tryParse(idString)),
        ),
      );
    }
  }
}
