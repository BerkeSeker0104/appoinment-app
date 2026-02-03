import '../../data/models/branch_model.dart';

class Favorite {
  final String userId;
  final String companyId;
  final BranchModel? company;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Favorite({
    required this.userId,
    required this.companyId,
    this.company,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.userId == userId &&
        other.companyId == companyId;
  }

  @override
  int get hashCode => userId.hashCode ^ companyId.hashCode;

  @override
  String toString() =>
      'Favorite(userId: $userId, companyId: $companyId, company: ${company?.name})';
}
