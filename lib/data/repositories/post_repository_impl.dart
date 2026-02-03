import 'dart:io';
import '../models/post_model.dart';
import '../services/post_api_service.dart';
import '../../domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostApiService _postApiService = PostApiService();

  @override
  Future<List<PostModel>> getPosts({String? companyId}) async {
    try {
      return await _postApiService.getPosts(companyId: companyId);
    } catch (e) {
      throw Exception('Gönderiler yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<PostModel> getPostById(String postId) async {
    try {
      return await _postApiService.getPostById(postId);
    } catch (e) {
      throw Exception('Gönderi bilgileri yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<PostModel> createPost({
    required String companyId,
    required String description,
    required List<File> files,
  }) async {
    try {
      return await _postApiService.createPost(
        companyId: companyId,
        description: description,
        files: files,
      );
    } catch (e) {
      throw Exception('Gönderi oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await _postApiService.deletePost(postId);
    } catch (e) {
      throw Exception('Gönderi silinirken hata oluştu: $e');
    }
  }
}
