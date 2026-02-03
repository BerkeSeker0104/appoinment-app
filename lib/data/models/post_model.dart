class PostModel {
  final String id;
  final String companyId;
  final String description;
  final List<String> files; // File URLs
  final bool isLiked;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.companyId,
    required this.description,
    required this.files,
    this.isLiked = false,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      companyId:
          json['companyId']?.toString() ?? json['company_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      files: _parseFiles(json['files'] ?? json['file']),
      isLiked: json['isLike']?.toString() == '1' || json['isLiked'] == true,
      likeCount: int.tryParse(json['likeCount']?.toString() ??
              json['like_count']?.toString() ??
              '0') ??
          0,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'description': description,
      // files will be handled separately in FormData for multipart upload
    };
  }

  static List<String> _parseFiles(dynamic files) {
    if (files == null) return [];

    if (files is List) {
      return files
          .map((e) => _parseFileUrl(e))
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // If it's a single file object with language keys (tr, en)
    if (files is Map<String, dynamic>) {
      final List<String> fileList = [];
      if (files['tr'] != null) fileList.add(_parseFileUrl(files['tr']));
      if (files['en'] != null) fileList.add(_parseFileUrl(files['en']));
      return fileList.where((url) => url.isNotEmpty).toList();
    }

    // If it's a single string
    if (files is String && files.isNotEmpty) {
      return [_parseFileUrl(files)];
    }

    return [];
  }

  static String _parseFileUrl(dynamic value) {
    if (value == null) return '';

    // If value is a Map (object with id, fileUrl, fileName), extract fileUrl
    if (value is Map<String, dynamic>) {
      final fileUrl = value['fileUrl']?.toString() ?? '';
      if (fileUrl.isEmpty) return '';
      return _buildFullUrl(fileUrl);
    }

    final filePath = value.toString();
    if (filePath.isEmpty) return '';

    return _buildFullUrl(filePath);
  }

  static String _buildFullUrl(String filePath) {
    // If it's already a full URL (starts with http/https), return as is
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    // If it's a relative path, add base URL
    const baseUrl = 'https://api.mandw.com.tr';
    // Add leading slash if not present
    final path = filePath.startsWith('/') ? filePath : '/$filePath';
    return '$baseUrl$path';
  }

  PostModel copyWith({
    String? id,
    String? companyId,
    String? description,
    List<String>? files,
    bool? isLiked,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      description: description ?? this.description,
      files: files ?? this.files,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PostModel(id: $id, companyId: $companyId, description: $description)';
}
