import 'package:permission_handler/permission_handler.dart';

/// Service for managing notification permissions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      PermissionStatus status = await Permission.notification.status;

      if (status.isDenied) {
        // Request permission
        status = await Permission.notification.request();
      }

      if (status.isPermanentlyDenied) {
        // Kalıcı red durumunda sadece false döndür, otomatik ayarlara yönlendirme
        return false;
      }

      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if notification permission is permanently denied
  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.notification.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for notification permission (manual action)
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
    }
  }

  /// Check if we can request notification permission
  /// Returns false if permission is permanently denied
  Future<bool> canRequestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return !status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }
}
