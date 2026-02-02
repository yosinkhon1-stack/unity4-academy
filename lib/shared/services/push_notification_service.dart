import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'local_notification_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    // Request notification permissions
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }

    // Subscribe to topics (Skip on web as it's not supported)
    if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic('announcements');
          await _messaging.subscribeToTopic('exam_results');
        } catch(e) {
          debugPrint('Topic subscription skipped or failed: $e');
        }
    }

    // Listener for messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = message.notification!;
        LocalNotificationService.showSimpleNotification(
          title: notification.title ?? "Yangi xabar",
          body: notification.body ?? "",
        );
      }
    });

    // Listener for when app is opened via a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened via notification: ${message.data}");
    });
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint("Subscribed to topic: $topic");
    } catch (e) {
      debugPrint("Topic subscription failed: $e");
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint("Unsubscribed from topic: $topic");
    } catch (e) {
      debugPrint("Topic unsubscription failed: $e");
    }
  }

  static Future<void> updateUserToken(BuildContext context, String userEmailOrId) async {
    try {
      debugPrint("Starting token update for $userEmailOrId...");
      // Small delay to ensure FCM is ready
      await Future.delayed(const Duration(seconds: 2));
      
      String? token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('user_tokens').doc(userEmailOrId).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
          'platform': 'android',
        }, SetOptions(merge: true));
        
        debugPrint("Token successfully updated in Firestore for: $userEmailOrId");
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Token yangilandi: $userEmailOrId"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
         debugPrint("FCM Token is null");
      }

      // Also listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('user_tokens').doc(userEmailOrId).set({
          'fcmToken': newToken,
          'lastUpdated': FieldValue.serverTimestamp(),
          'platform': 'android',
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Detailed error updating token for $userEmailOrId: $e");
      // Silencing snackbar on web for service worker registration errors
      final isWebErr = e.toString().contains('service-worker-registration');
      if (context.mounted && !isWebErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Token xatosi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper to trigger a notification (intended for Cloud Functions to process)
  static Future<void> sendNotificationRequest({
    String? targetUserEmail,
    String? topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool toAll = false,
  }) async {
    await FirebaseFirestore.instance.collection('notification_requests').add({
      'targetEmail': targetUserEmail,
      'topic': topic,
      'title': title,
      'body': body,
      'data': data,
      'toAll': toAll,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
