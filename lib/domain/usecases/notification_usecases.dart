import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationUseCases {
  final NotificationRepository _repository;

  NotificationUseCases(this._repository);

  Future<List<Notification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return await _repository.getNotifications(page: page, limit: limit);
  }

  Future<int> getUnreadCount() async {
    return await _repository.getUnreadCount();
  }

  Future<bool> markAsRead(String notificationId) async {
    return await _repository.markAsRead(notificationId);
  }
}












