import '../../data/models/comment_model.dart';

abstract class CommentRepository {
  Future<List<CommentModel>> getComments({
    required String companyId,
    int page,
    int limit,
  });

  Future<Map<String, dynamic>> getCompanyRatingStats({
    required String companyId,
  });

  Future<CommentModel> createComment({
    required String appointmentId,
    required int rating,
    String? comment,
  });

  Future<CommentModel> createRating({
    required String appointmentId,
    required int rating,
  });

  Future<void> deleteComment({
    required String commentId,
  });
}

