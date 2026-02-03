import '../models/comment_model.dart';
import '../services/comment_api_service.dart';
import '../../domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentApiService _commentApiService = CommentApiService();

  @override
  Future<List<CommentModel>> getComments({
    required String companyId,
    int page = 1,
    int limit = 20,
  }) async {
    if (companyId.isEmpty) {
      throw Exception('Şirket ID\'si zorunludur');
    }

    try {
      return await _commentApiService.getComments(
        companyId: companyId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Yorumlar yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCompanyRatingStats({
    required String companyId,
  }) async {
    if (companyId.isEmpty) {
      throw Exception('Şirket ID\'si zorunludur');
    }

    try {
      return await _commentApiService.getCompanyRatingStats(
        companyId: companyId,
      );
    } catch (e) {
      throw Exception('Puan istatistikleri alınırken hata oluştu: $e');
    }
  }

  @override
  Future<CommentModel> createComment({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }
    if (rating <= 0) {
      throw Exception('Puan 1 ile 5 arasında olmalıdır');
    }

    try {
      return await _commentApiService.submitComment(
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      throw Exception('Yorum oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<CommentModel> createRating({
    required String appointmentId,
    required int rating,
  }) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }
    if (rating <= 0) {
      throw Exception('Puan 1 ile 5 arasında olmalıdır');
    }

    try {
      return await _commentApiService.submitRating(
        appointmentId: appointmentId,
        rating: rating,
      );
    } catch (e) {
      throw Exception('Puan gönderilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteComment({required String commentId}) async {
    if (commentId.isEmpty) {
      throw Exception('Yorum ID\'si zorunludur');
    }

    try {
      await _commentApiService.deleteComment(commentId: commentId);
    } catch (e) {
      throw Exception('Yorum silinirken hata oluştu: $e');
    }
  }
}

