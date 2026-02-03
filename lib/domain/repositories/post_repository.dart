import 'dart:io';
import '../../data/models/post_model.dart';

abstract class PostRepository {
  Future<List<PostModel>> getPosts({String? companyId});
  Future<PostModel> getPostById(String postId);
  Future<PostModel> createPost({
    required String companyId,
    required String description,
    required List<File> files,
  });
  Future<void> deletePost(String postId);
}
