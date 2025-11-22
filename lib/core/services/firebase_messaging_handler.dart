import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 🎯 Quản lý thông báo FCM (Mobile + Web)
class FirebaseMessagingHandler {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// 🔧 Khởi tạo notification channel cho Android
  static Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'default_channel',
      'Delivery Notifications',
      description: 'Thông báo từ hệ thống giao hàng',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (kDebugMode) {
      print('✅ Local Notifications initialized');
    }
  }

  /// 📩 Hiển thị local notification khi có message foreground hoặc background
  static Future<void> showLocalNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Delivery Notifications',
      channelDescription: 'Thông báo từ hệ thống giao hàng',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();
    const notifDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Thông báo mới',
      message.notification?.body ?? '',
      notifDetails,
    );
  }
}
