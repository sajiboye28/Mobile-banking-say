import 'package:shared_preferences/shared_preferences.dart';

/// Stub notification service — Firebase Messaging removed.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// No-op initializer kept for API compatibility.
  Future<void> init() async {}

  /// No-op token updater kept for API compatibility.
  Future<void> updateFcmToken(String uid) async {}

  /// Save the preference for whether push notifications are enabled.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);
  }
}
