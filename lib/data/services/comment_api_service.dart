import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/comment_model.dart';

class CommentApiService {
  final Dio _apiClient;
  final TokenStorage _tokenStorage = TokenStorage();

  CommentApiService([Dio? dio])
      : _apiClient = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: ApiConstants.defaultHeaders,
              ),
            ) {
    if (_apiClient.options.baseUrl.isEmpty) {
      _apiClient.options = _apiClient.options.copyWith(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      );
    }
  }

  // Get company scores (comments) for a company
  Future<List<CommentModel>> getComments({
    required String companyId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _apiClient.get(
        ApiConstants.companyScore,
        queryParameters: {
          'companyId': companyId,
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = _asMap(response.data);
      final commentsData = data['data'] as List<dynamic>? ?? [];

      return commentsData
          .map((commentJson) => CommentModel.fromJson(commentJson))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Submit a company score (comment with rating)
  Future<CommentModel> submitComment({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _apiClient.post(
        ApiConstants.companyScore,
        data: {
          'appointmentId': int.tryParse(appointmentId) ?? appointmentId,
          'score': rating,
          'comment': comment ?? '',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = _asMap(response.data);
      final commentData = data['data'] as Map<String, dynamic>? ?? {};

      return CommentModel.fromJson(commentData);
    } catch (e) {
      rethrow;
    }
  }

  // Submit only a rating (without comment) - uses same endpoint
  Future<CommentModel> submitRating({
    required String appointmentId,
    required int rating,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _apiClient.post(
        ApiConstants.companyScore,
        data: {
          'appointmentId': int.tryParse(appointmentId) ?? appointmentId,
          'score': rating,
          'comment': '',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = _asMap(response.data);
      final commentData = data['data'] as Map<String, dynamic>? ?? {};

      return CommentModel.fromJson(commentData);
    } catch (e) {
      rethrow;
    }
  }

  // Get company rating statistics
  Future<Map<String, dynamic>> getCompanyRatingStats({
    required String companyId,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _apiClient.get(
        ApiConstants.companyScore,
        queryParameters: {
          'companyId': companyId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = _asMap(response.data);
      final commentsData = data['data'] as List<dynamic>? ?? [];

      // Calculate average rating and count
      if (commentsData.isEmpty) {
        return {
          'averageRating': 3.0, // Default starting rating
          'totalReviews': 0,
        };
      }

      double totalScore = 0;
      int validScores = 0;

      for (var commentJson in commentsData) {
        final comment = CommentModel.fromJson(commentJson);
        if (comment.score > 0) {
          totalScore += comment.score;
          validScores++;
        }
      }

      final averageRating = validScores > 0 ? totalScore / validScores : 3.0;

      return {
        'averageRating': averageRating,
        'totalReviews': validScores,
      };
    } catch (e) {
      // Return default values if API fails
      return {
        'averageRating': 3.0,
        'totalReviews': 0,
      };
    }
  }

  // Get company score by ID
  Future<CommentModel> getCompanyScoreById({
    required String scoreId,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final response = await _apiClient.get(
        '${ApiConstants.companyScore}/$scoreId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = _asMap(response.data);
      final commentData = data['data'] as Map<String, dynamic>? ?? {};

      return CommentModel.fromJson(commentData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a company score
  Future<void> deleteComment({
    required String commentId,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await _apiClient.delete(
        '${ApiConstants.companyScore}/$commentId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to safely convert response data to Map
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}
