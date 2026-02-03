import 'branch_model.dart';

class FavoriteModel {
  final String userId;
  final String companyId;
  final BranchModel? company;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FavoriteModel({
    required this.userId,
    required this.companyId,
    this.company,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      userId: json['userId']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      company: json['company'] != null
          ? BranchModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyId': companyId,
      'company': company?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteModel &&
        other.userId == userId &&
        other.companyId == companyId;
  }

  @override
  int get hashCode => userId.hashCode ^ companyId.hashCode;

  @override
  String toString() =>
      'FavoriteModel(userId: $userId, companyId: $companyId, company: ${company?.name})';
}
