import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationsService {
  NotificationsService._();

  static final instance = NotificationsService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    ////access

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    final token = await _messaging.getToken();
    debugPrint('FCM TOKEN: $token');

    /// foregraound
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showSnackBar(context, message);
    });

    // background, terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('OPENED FROM BG: ${message.notification?.title}');

      ///  навигация
    });

    /// not clicked
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('OPENED FROM START');
    }
  }

  void _showSnackBar(BuildContext context, RemoteMessage message) {
    final notification = message.notification;

    if (notification == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title ?? ''),
            if (notification.body != null) Text(notification.body!),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
