import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementApiService {
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

  /// Converts expiredDate string to UTC ISO format.
  /// Handles various input formats and converts local time to UTC.
  String _formatExpiredDate(String expiredDate) {
    try {
      if (expiredDate.contains('T') && expiredDate.endsWith('Z')) {
        return expiredDate;
      }
      
      DateTime dateTime;
      if (expiredDate.contains(' ')) {
        final isoString = expiredDate.replaceAll(' ', 'T');
        dateTime = DateTime.parse(isoString);
      } else {
        dateTime = DateTime.parse(expiredDate);
      }
      
      return dateTime.toUtc().toIso8601String();
    } catch (e) {
      return expiredDate;
    }
  }

  Future<bool> createAnnouncement({
    required String content,
    required String expiredDate,
  }) async {
    try {
      final formattedExpiredDate = _formatExpiredDate(expiredDate);
      
      final response = await _apiClient.post(
        ApiConstants.announcements,
        data: {
          'content': content,
          'expiredDate': formattedExpiredDate,
        },
      );
      
      final data = _asMap(response.data);
      
      if (data['status'] == true) {
        return true;
      }
      throw Exception('Duyuru oluşturulurken hata oluştu');
    } catch (e) {
      throw Exception('Duyuru oluşturulurken hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> getAnnouncementsPaginated({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _apiClient.get(ApiConstants.announcements);
      final data = _asMap(response.data);

      if (data['status'] != true) {
        throw Exception('API hatası: status false');
      }

      final announcementsList = _extractAnnouncementsList(data);
      final newAnnouncements = announcementsList
          .map((item) => AnnouncementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final hasMore = _calculateHasMore(data, page, announcementsList.length, limit);

      return {
        'announcements': newAnnouncements,
        'hasMore': hasMore,
      };
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return {'announcements': [], 'hasMore': false};
      }
      throw Exception('Sayfalı duyurular yüklenirken hata oluştu: $e');
    }
  }

  List<dynamic> _extractAnnouncementsList(Map<String, dynamic> data) {
    if (data['data'] is List) return data['data'] as List<dynamic>;
    if (data['announcements'] is List) return data['announcements'] as List<dynamic>;
    if (data['items'] is List) return data['items'] as List<dynamic>;
    if (data is List) return data as List<dynamic>;
    return [];
  }

  bool _calculateHasMore(
    Map<String, dynamic> data,
    int page,
    int listLength,
    int limit,
  ) {
    final pagination = data['pagination'] as Map<String, dynamic>?;
    if (pagination != null) {
      final currentPage = pagination['currentPage'] as int? ?? page;
      final lastPage = pagination['pageLastCount'] as int? ?? 1;
      return currentPage < lastPage;
    }
    return listLength >= limit;
  }

  Future<bool> updateAnnouncement({
    required int id,
    required String content,
    required String expiredDate,
  }) async {
    try {
      final formattedExpiredDate = _formatExpiredDate(expiredDate);
      
      final response = await _apiClient.put(
        '${ApiConstants.announcements}/$id',
        data: {
          'content': content,
          'expiredDate': formattedExpiredDate,
        },
      );
      
      final data = _asMap(response.data);
      
      if (data['status'] == true) {
        return true;
      }
      throw Exception('Duyuru güncellenirken hata oluştu');
    } catch (e) {
      throw Exception('Duyuru güncellenirken hata oluştu: $e');
    }
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      final response = await _apiClient.delete('${ApiConstants.announcements}/$id');
      final data = _asMap(response.data);
      
      if (data['status'] == true) {
        return true;
      }
      throw Exception('Duyuru silinirken hata oluştu');
    } catch (e) {
      throw Exception('Duyuru silinirken hata oluştu: $e');
    }
  }

  Future<AnnouncementModel> getAnnouncementById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.announcements}/$id');
      final data = _asMap(response.data);

      Map<String, dynamic> announcementData;
      if (data['data'] is Map<String, dynamic>) {
        announcementData = data['data'];
      } else if (data['announcement'] is Map<String, dynamic>) {
        announcementData = data['announcement'];
      } else {
        announcementData = data;
      }

      return AnnouncementModel.fromJson(announcementData);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception('Duyuru bulunamadı');
      }
      throw Exception('Duyuru bilgileri yüklenirken hata oluştu: $e');
    }
  }
}
