class CompanyUserModel {
  final String companyId;
  final String userId;
  final bool isOwner;
  final String createdAt;
  final String state;
  final UserDetail userDetail;
  final CompanyDetail companyDetail;

  CompanyUserModel({
    required this.companyId,
    required this.userId,
    required this.isOwner,
    required this.createdAt,
    this.state = '0',
    required this.userDetail,
    required this.companyDetail,
  });

  factory CompanyUserModel.fromJson(Map<String, dynamic> json) {
    var userDetailJson = json['userDetail'] != null && json['userDetail'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['userDetail'])
        : <String, dynamic>{};
    
    // Fallback: If picture is in root but not in userDetail, copy it
    if (json['picture'] != null && userDetailJson['picture'] == null) {
        userDetailJson['picture'] = json['picture'];
    }

    // userId fallback: Try json['userId'], then userDetail['id']
    String resolvedUserId = json['userId']?.toString() ?? '';
    if (resolvedUserId.isEmpty && userDetailJson['id'] != null) {
      resolvedUserId = userDetailJson['id'].toString();
    }

    return CompanyUserModel(
      companyId: json['companyId'] ?? '',
      userId: resolvedUserId,
      isOwner: json['isOwner'] ?? false,
      createdAt: json['createdAt'] ?? '',
      state: json['state']?.toString() ?? userDetailJson['state']?.toString() ?? '0',
      userDetail: UserDetail.fromJson(userDetailJson),
      companyDetail: CompanyDetail.fromJson(json['companyDetail'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'userId': userId,
      'isOwner': isOwner,
      'createdAt': createdAt,
      'state': state,
      'userDetail': userDetail.toJson(),
      'companyDetail': companyDetail.toJson(),
    };
  }
}

class UserDetail {
  final String id;
  final String name;
  final String surname;
  final String phoneCode;
  final String phone;
  final String? email;
  final String gender;
  final String? picture;

  UserDetail({
    required this.id,
    required this.name,
    required this.surname,
    required this.phoneCode,
    required this.phone,
    this.email,
    required this.gender,
    this.picture,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      phoneCode: json['phoneCode'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      gender: json['gender'] ?? '',
      picture: json['picture'] ?? json['image'] ?? json['avatar'] ?? json['photo'] ?? json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'phoneCode': phoneCode,
      'phone': phone,
      'email': email,
      'gender': gender,
      'picture': picture,
    };
  }

  String get fullName => '$name $surname';
}

class CompanyDetail {
  final String id;
  final String name;

  CompanyDetail({
    required this.id,
    required this.name,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    return CompanyDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
