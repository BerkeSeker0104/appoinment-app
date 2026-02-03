import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.text,
    super.senderId,
    super.receiverId,
    super.companyId,
    super.customerId,
    required super.createdAt,
    super.updatedAt,
    super.isRead,
    super.isFromMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen isRead değerini işle: "0" = okunmamış, "1" = okunmuş
    bool isRead = false;
    try {
      if (json['isRead'] != null) {
        if (json['isRead'] is String) {
          isRead = json['isRead'] == "1";
        } else if (json['isRead'] is int) {
          isRead = json['isRead'] == 1;
        } else if (json['isRead'] is bool) {
          isRead = json['isRead'] as bool;
        }
      } else if (json['read'] != null) {
        if (json['read'] is String) {
          isRead = json['read'] == "1";
        } else if (json['read'] is int) {
          isRead = json['read'] == 1;
        } else if (json['read'] is bool) {
          isRead = json['read'] as bool;
        }
      }
    } catch (e) {
      // isRead parse hatası durumunda varsayılan değer
      isRead = false;
    }

    // isFromMe değerini belirle - bu frontend'de set edilecek
    final isFromMe = json['isFromMe'] as bool? ?? false;

    return MessageModel(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      senderId: json['writerId']?.toString() ??
          json['senderId']?.toString(), // writerId öncelikli
      receiverId: json['receiverId']?.toString(),
      companyId: json['companyId']?.toString(),
      customerId: json['customerId']?.toString(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      isRead: isRead, // Backend'den gelen değeri kullan
      isFromMe: isFromMe,
    );
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();

    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'companyId': companyId,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isRead': isRead,
      'isFromMe': isFromMe,
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      text: message.text,
      senderId: message.senderId,
      receiverId: message.receiverId,
      companyId: message.companyId,
      customerId: message.customerId,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      isRead: message.isRead,
      isFromMe: message.isFromMe,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      text: text,
      senderId: senderId,
      receiverId: receiverId,
      companyId: companyId,
      customerId: customerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isRead: isRead,
      isFromMe: isFromMe,
    );
  }
}
