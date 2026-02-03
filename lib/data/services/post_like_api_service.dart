import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';

class PostLikeApiService {
  final ApiClient _apiClient = ApiClient();

  Future<void> likePost(String postId) async {
    try {
      await _apiClient.post(
        ApiConstants.postLikes,
        data: {'postId': postId},
      );
    } catch (e) {
      throw Exception('Post beğenilirken hata oluştu: $e');
    }
  }
}
