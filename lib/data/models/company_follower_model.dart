class CompanyFollowerModel {
  final String id;
  final String userId;
  final String companyId;
  final String? userFullName; // For company viewing followers
  final String? userProfileImage; // For company viewing followers
  final String? companyName; // For customer viewing following
  final String? companyLogo; // For customer viewing following
  final DateTime createdAt;

  CompanyFollowerModel({
    required this.id,
    required this.userId,
    required this.companyId,
    this.userFullName,
    this.userProfileImage,
    this.companyName,
    this.companyLogo,
    required this.createdAt,
  });

  factory CompanyFollowerModel.fromJson(Map<String, dynamic> json) {
    String? fullName;
    String? profileImage;
    String? companyNameStr;

    // Parse user details from nested object if available
    if (json['userDetail'] != null) {
      final name = json['userDetail']['name']?.toString() ?? '';
      final surname = json['userDetail']['surname']?.toString() ?? '';
      if (name.isNotEmpty || surname.isNotEmpty) {
        fullName = '$name $surname'.trim();
      }
      // Try to get profile image from userDetail if available (common pattern)
      profileImage = json['userDetail']['profileImg']?.toString();
    }

    // Parse company details from nested object if available
    if (json['companyDetail'] != null) {
      companyNameStr = json['companyDetail']['name']?.toString();
    }

    return CompanyFollowerModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      userFullName: fullName ?? json['userFullName']?.toString() ?? json['userName']?.toString(),
      userProfileImage: profileImage ?? json['userProfileImage']?.toString() ?? json['userImage']?.toString(),
      companyName: companyNameStr ?? json['companyName']?.toString(),
      companyLogo: json['companyLogo']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'companyId': companyId,
      'userFullName': userFullName,
      'userProfileImage': userProfileImage,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
