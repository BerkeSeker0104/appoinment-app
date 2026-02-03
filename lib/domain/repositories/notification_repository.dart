import '../entities/notification.dart';

abstract class NotificationRepository {
  // Get notifications list with pagination
  Future<List<Notification>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  // Get unread notification count
  Future<int> getUnreadCount();

  // Mark notification as read
  Future<bool> markAsRead(String notificationId);
}












