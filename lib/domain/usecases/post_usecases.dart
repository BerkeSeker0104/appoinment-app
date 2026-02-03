import 'dart:io';
import '../../data/models/post_model.dart';
import '../repositories/post_repository.dart';

class PostUseCases {
  final PostRepository _postRepository;

  PostUseCases(this._postRepository);

  // Get all posts
  Future<List<PostModel>> getPosts({String? companyId}) async {
    return await _postRepository.getPosts(companyId: companyId);
  }

  // Get a specific post
  Future<PostModel> getPostById(String postId) async {
    if (postId.isEmpty) {
      throw Exception('Gönderi ID gerekli');
    }
    return await _postRepository.getPostById(postId);
  }

  // Create a new post
  Future<PostModel> createPost({
    required String companyId,
    required String description,
    required List<File> files,
  }) async {
    // Validation
    if (companyId.isEmpty) {
      throw Exception('Lütfen firma seçiniz');
    }

    if (description.isEmpty) {
      throw Exception('Lütfen açıklama giriniz');
    }

    if (description.length < 10) {
      throw Exception('Açıklama en az 10 karakter olmalıdır');
    }

    if (files.isEmpty) {
      throw Exception('Lütfen en az bir dosya seçiniz');
    }

    // Check file sizes (max 5MB per file)
    const maxFileSize = 5 * 1024 * 1024; // 5MB in bytes
    for (var file in files) {
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('Dosya boyutu maksimum 5MB olabilir');
      }
    }

    return await _postRepository.createPost(
      companyId: companyId,
      description: description,
      files: files,
    );
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    if (postId.isEmpty) {
      throw Exception('Gönderi ID gerekli');
    }
    await _postRepository.deletePost(postId);
  }

  // Filter posts by company
  Future<List<PostModel>> getPostsByCompany(String companyId) async {
    if (companyId.isEmpty) {
      return [];
    }

    try {
      // Directly request posts for the specific company from API
      final posts = await _postRepository.getPosts(companyId: companyId);
      return posts;
    } catch (e) {
      return []; // Return empty list for better UX
    }
  }

  // Search posts by description
  Future<List<PostModel>> searchPosts(String query, {String? companyId}) async {
    if (query.isEmpty) {
      return await _postRepository.getPosts(companyId: companyId);
    }

    final allPosts = await _postRepository.getPosts(companyId: companyId);
    return allPosts.where((post) {
      return post.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
