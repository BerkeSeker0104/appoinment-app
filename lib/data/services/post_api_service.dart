import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/post_model.dart';

class PostApiService {
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

  // Get all posts
  Future<List<PostModel>> getPosts({String? companyId}) async {
    try {
      final queryParams = companyId != null ? {'companyId': companyId} : null;

      final response = await _apiClient.get(
        ApiConstants.posts,
        queryParameters: queryParams,
      );
      final data = _asMap(response.data);

      List<dynamic> postsList = [];
      if (data['data'] is List) {
        postsList = data['data'] as List<dynamic>;
      } else if (data['posts'] is List) {
        postsList = data['posts'] as List<dynamic>;
      } else if (data['items'] is List) {
        postsList = data['items'] as List<dynamic>;
      } else if (data is List) {
        postsList = data as List<dynamic>;
      }

      return postsList.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      return []; // Return empty list instead of throwing for better UX
    }
  }

  // Get a specific post by ID
  Future<PostModel> getPostById(String postId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.posts}/$postId');
      final data = _asMap(response.data);

      Map<String, dynamic> postData;
      if (data['data'] is Map<String, dynamic>) {
        postData = data['data'];
      } else if (data['post'] is Map<String, dynamic>) {
        postData = data['post'];
      } else if (data['data'] is List && (data['data'] as List).isNotEmpty) {
        // If response is a list, find the post with matching ID
        final postsList = data['data'] as List;
        postData = postsList.firstWhere(
          (p) => p['id'].toString() == postId,
          orElse: () => postsList.first,
        );
      } else {
        postData = data;
      }

      return PostModel.fromJson(postData);
    } catch (e) {
      rethrow;
    }
  }

  // Create a new post
  Future<PostModel> createPost({
    required String companyId,
    required String description,
    required List<File> files,
  }) async {
    try {
      // FormData kullan (resim upload için)
      final formData = FormData();

      // Add text fields
      formData.fields.add(MapEntry('companyId', companyId));
      formData.fields.add(MapEntry('description', description));

      // Add files
      if (files.isNotEmpty) {
        for (var i = 0; i < files.length; i++) {
          final file = files[i];
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'files', // Backend expects 'files' field
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );
        }
      }

      final response = await _apiClient.post(
        ApiConstants.posts,
        data: formData,
      );

      final data = _asMap(response.data);

      // Backend returns the created post
      PostModel createdPost;
      if (data['data'] is Map<String, dynamic>) {
        createdPost = PostModel.fromJson(data['data']);
      } else if (data['post'] is Map<String, dynamic>) {
        createdPost = PostModel.fromJson(data['post']);
      } else {
        // Backend returns simple {status: true, message: "..."}
        // Create a basic post model with the data we sent
        createdPost = PostModel(
          id:
              data['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          companyId: companyId,
          description: description,
          files: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return createdPost;
    } on DioException catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;

      if (e.response?.statusCode == 404) {
        throw Exception(
          'Gönderi ekleme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _apiClient.delete('${ApiConstants.posts}/$postId');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Gönderi silme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      throw Exception('Gönderi silinirken hata oluştu: $e');
    }
  }
}
