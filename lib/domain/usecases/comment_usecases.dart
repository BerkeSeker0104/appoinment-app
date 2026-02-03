import '../../data/models/comment_model.dart';
import '../repositories/comment_repository.dart';

class CommentUseCases {
  final CommentRepository _commentRepository;

  CommentUseCases(this._commentRepository);

  Future<List<CommentModel>> fetchCompanyComments({
    required String companyId,
    int page = 1,
    int limit = 20,
  }) async {
    return await _commentRepository.getComments(
      companyId: companyId,
      page: page,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> fetchCompanyRatingStats({
    required String companyId,
  }) async {
    return await _commentRepository.getCompanyRatingStats(
      companyId: companyId,
    );
  }

  Future<CommentModel> createComment({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    return await _commentRepository.createComment(
      appointmentId: appointmentId,
      rating: rating,
      comment: comment,
    );
  }

  Future<CommentModel> createRating({
    required String appointmentId,
    required int rating,
  }) async {
    return await _commentRepository.createRating(
      appointmentId: appointmentId,
      rating: rating,
      );
    }

  Future<void> deleteComment({
    required String commentId,
  }) async {
    await _commentRepository.deleteComment(commentId: commentId);
  }
}

