import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification_api_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService _notificationApiService;

  NotificationRepositoryImpl(this._notificationApiService);

  @override
  Future<List<Notification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await _notificationApiService.getNotifications(
        page: page,
        limit: limit,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await _notificationApiService.getUnreadCount();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    try {
      return await _notificationApiService.markAsRead(notificationId);
    } catch (e) {
      rethrow;
    }
  }
}

