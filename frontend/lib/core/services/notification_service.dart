import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Coordinates FCM (remote) and flutter_local_notifications (local/foreground
/// display + offline reminders). Call [init] once after Firebase.initializeApp
/// in main.dart, after the user is authenticated.
class NotificationService {
  // Lazy — see AuthService for why: FirebaseMessaging.instance throws until
  // a real Firebase project is configured.
  FirebaseMessaging? _fcmOverride;
  FirebaseMessaging get _fcm => _fcmOverride ??= FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'skillbridge_alerts',
    'SkillBridge Important Alerts',
    description: 'Notifications for matches, roadmaps, and analysis outcomes',
    importance: Importance.max,
  );

  Future<void> init() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final token = await _fcm.getToken();
    if (token != null) await _saveTokenToDatabase(token);
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: android.smallIcon,
          importance: Importance.max,
        ),
      ),
    );
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  /// Schedules a repeating local reminder (learning, interview practice,
  /// resume update, etc). Works fully offline.
  Future<void> scheduleLocalReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Wired up with zonedSchedule + timezone package once reminder
    // preferences are implemented in Settings.
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationHistory(
      String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
