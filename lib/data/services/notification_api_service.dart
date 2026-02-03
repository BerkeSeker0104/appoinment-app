import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // Get notifications list with pagination
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final String endpoint = ApiConstants.notifications;
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'dataCount': limit,
      };


      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
      );
      final data = _asMap(response.data);

      if (data['status'] == true && data['data'] is List) {
        final notificationsList = (data['data'] as List)
            .map((json) {
              final parsed = NotificationModel.fromJson(json);
              return parsed;
            })
            .toList();

        return notificationsList;
      } else {
        return [];
      }
    } catch (e) {
      
      // If 404 or empty response, return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }

      rethrow;
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final String endpoint = ApiConstants.notificationCount;


      final response = await _apiClient.get(endpoint);
      final data = _asMap(response.data);


      if (data['status'] == true) {
        // Try different possible keys for count
        final count = data['count'] ?? 
                     data['unreadCount'] ?? 
                     data['unread_count'] ?? 
                     data['data'] ?? 
                     0;
        
        final countInt = count is int ? count : (count is String ? int.tryParse(count) ?? 0 : 0);
        return countInt;
      } else {
        return 0;
      }
    } catch (e) {
      
      // If 404 or error, return 0
      return 0;
    }
  }

  // Mark notification as read (if backend supports it)
  Future<bool> markAsRead(String notificationId) async {
    try {
      final String endpoint = '${ApiConstants.notifications}/$notificationId/read';


      final response = await _apiClient.post(
        endpoint,
        data: {},
      );
      final data = _asMap(response.data);


      if (data['status'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      
      // If endpoint doesn't exist, just return false (not critical)
      return false;
    }
  }
}












