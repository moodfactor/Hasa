import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FcmApi {
  final firebaseMessaging = FirebaseMessaging.instance;

  Future<void> handlePermission() async {
    // يمكنك تنفيذ طلب الأذونات هنا إذا لزم الأمر.
  }

  Future<String?> getToken() async {
    final fcmtoken = await firebaseMessaging.getToken();
    log("FCM Token: $fcmtoken");
    return fcmtoken;
  }

  /// تهيئة الإشعارات مع استقبال navigatorKey للتوجيه عند الضغط على الإشعار.
  Future<void> initNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    await getToken();
    await firebaseMessaging.requestPermission();
    handleForeground();

    // تسجيل الدالة لمعالجة الرسائل في الخلفية.
    FirebaseMessaging.onBackgroundMessage(handleBackgroundFcm);

    // الاستماع للحدث عند الضغط على الإشعار.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Notification clicked: ${message.notification?.title}");
      // التوجيه إلى صفحة الإشعارات.
      navigatorKey.currentState?.pushNamed('/notifications');
    });
  }

  handleForeground() async {
    // إنشاء قناة إشعارات لنظام Android.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // المعرف
      'High Importance Notifications', // العنوان
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    // تهيئة FlutterLocalNotificationsPlugin.
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // الاستماع للرسائل الواردة عند تواجد التطبيق في المقدمة.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      log("Received notification: ${notification?.title}");

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon:
                  'img', // تأكد من أن لديك أيقونة مسماة "img" في resources الخاصة بك.
            ),
          ),
        );
      }
    });
  }

  static Future<void> handleBackgroundFcm(RemoteMessage message) async {
    log("Background notification: ${message.notification?.title}");
    log("Background message: ${message.notification?.body}");
  }
}
