class Message {
  final String id;
  final String text;
  final String? senderId;
  final String? receiverId;
  final String? companyId;
  final String? customerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final bool isFromMe;

  const Message({
    required this.id,
    required this.text,
    this.senderId,
    this.receiverId,
    this.companyId,
    this.customerId,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.isFromMe = false,
  });

  Message copyWith({
    String? id,
    String? text,
    String? senderId,
    String? receiverId,
    String? companyId,
    String? customerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isFromMe,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isFromMe: isFromMe ?? this.isFromMe,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
