class Conversation {
  final int id;
  final String? companyName;
  final String? customerName;
  final String? companyImage;
  final String? customerImage;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final String? companyId;
  final String? customerId;
  final bool hasUnreadMessages; // Yeni alan: okunmamış mesaj var mı?

  const Conversation({
    required this.id,
    this.companyName,
    this.customerName,
    this.companyImage,
    this.customerImage,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    this.companyId,
    this.customerId,
    this.hasUnreadMessages = false,
  });

  Conversation copyWith({
    int? id,
    String? companyName,
    String? customerName,
    String? companyImage,
    String? customerImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    String? companyId,
    String? customerId,
    bool? hasUnreadMessages,
  }) {
    return Conversation(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      customerName: customerName ?? this.customerName,
      companyImage: companyImage ?? this.companyImage,
      customerImage: customerImage ?? this.customerImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ConversationModel extends Conversation {
  // Backend'den gelen orijinal conversation ID (string UUID veya int)
  final String? originalId;

  const ConversationModel({
    required super.id,
    super.companyName,
    super.customerName,
    super.companyImage,
    super.customerImage,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount,
    super.isActive,
    super.companyId,
    super.customerId,
    super.hasUnreadMessages,
    this.originalId,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    try {
      // Gerçek API response yapısına göre parse et
      final companyDetail = json['companyDetail'] as Map<String, dynamic>?;
      final userDetail = json['userDetail'] as Map<String, dynamic>?;

      // Backend'den gelen texts alanını kontrol et (okunmamış mesaj var mı?)
      final hasUnreadMessages = json['texts'] != null;

      // ID string (UUID) veya int olabilir
      final idValue = json['id'];
      int parsedId;
      String? originalIdString;
      
      if (idValue is int) {
        parsedId = idValue;
        originalIdString = idValue.toString();
      } else if (idValue is String) {
        originalIdString = idValue;
        // UUID string ise, hash kullan (unique olması için)
        parsedId = int.tryParse(idValue) ?? idValue.hashCode.abs();
      } else {
        parsedId = 0;
        originalIdString = null;
      }
      
      return ConversationModel(
        id: parsedId,
        originalId: originalIdString,
        companyName: _sanitizeNamePart(companyDetail?['name']),
        customerName: _buildCustomerName(userDetail),
        companyImage: companyDetail?['picture'] as String?,
        customerImage: null, // API'de customer image yok
        lastMessage: 'Son mesaj', // Placeholder, gerçek mesaj gelecek
        lastMessageTime: _parseDateTime(json['lastMessageDate']),
        unreadCount: 0, // Placeholder, gerçek unread count gelecek
        isActive: true,
        companyId: json['companyId']?.toString(),
        customerId: json['userId']?.toString(),
        hasUnreadMessages:
            hasUnreadMessages, // Backend'den gelen texts kontrolü
      );
    } catch (e) {
      rethrow;
    }
  }

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': originalId ?? id.toString(),
      'companyName': companyName,
      'customerName': customerName,
      'companyImage': companyImage,
      'customerImage': customerImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'companyId': companyId,
      'customerId': customerId,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      companyName: conversation.companyName,
      customerName: conversation.customerName,
      companyImage: conversation.companyImage,
      customerImage: conversation.customerImage,
      lastMessage: conversation.lastMessage,
      lastMessageTime: conversation.lastMessageTime,
      unreadCount: conversation.unreadCount,
      isActive: conversation.isActive,
      companyId: conversation.companyId,
      customerId: conversation.customerId,
      hasUnreadMessages: conversation.hasUnreadMessages,
    );
  }

  Conversation toEntity() {
    return Conversation(
      id: id,
      companyName: companyName,
      customerName: customerName,
      companyImage: companyImage,
      customerImage: customerImage,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isActive: isActive,
      companyId: companyId,
      customerId: customerId,
      hasUnreadMessages: hasUnreadMessages,
    );
  }

  static String? _sanitizeNamePart(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    return str;
  }

  static String? _buildCustomerName(Map<String, dynamic>? userDetail) {
    if (userDetail == null || userDetail.isEmpty) return null;

    // Önce tam isim alanlarını dene
    for (final key in ['fullName', 'full_name', 'fullname']) {
      final fullName = _sanitizeNamePart(userDetail[key]);
      if (fullName != null) return fullName;
    }

    // Birincil isim ve soyisim alanlarını oku
    final firstName = _sanitizeNamePart(
      userDetail['name'] ?? userDetail['firstName'] ?? userDetail['first_name'],
    );
    final lastName = _sanitizeNamePart(
      userDetail['surname'] ??
          userDetail['lastName'] ??
          userDetail['last_name'],
    );

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName;
    if (lastName != null) return lastName;

    // Kullanıcı adı veya takma ad varsa onu kullan
    final username =
        _sanitizeNamePart(userDetail['username'] ?? userDetail['userName']);
    if (username != null) return username;

    // Nested user objesi varsa onu da kontrol et
    final nestedUser = userDetail['user'];
    if (nestedUser is Map<String, dynamic>) {
      final nestedName = _buildCustomerName(nestedUser);
      if (nestedName != null) return nestedName;
    }

    return null;
  }
}
