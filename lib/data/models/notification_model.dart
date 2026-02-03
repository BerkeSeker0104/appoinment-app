import 'dart:convert';
import '../../core/services/locale_service.dart';
import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    super.isRead,
    required super.createdAt,
    super.updatedAt,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final titleValue = json['title'] ?? json['subject'];
    final messageValue = json['message'] ?? json['body'] ?? json['content'];
    
    final parsedTitle = _parseLocalizedString(titleValue);
    final parsedMessage = _parseLocalizedString(messageValue);
    
    final model = NotificationModel(
      id: json['id']?.toString() ?? '',
      title: parsedTitle,
      message: parsedMessage,
      type: _parseNotificationType(json['type'] ?? json['notificationType']),
      isRead: _parseIsRead(json['isRead'] ?? json['read'] ?? json['is_read']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseNullableDateTime(json['updatedAt'] ?? json['updated_at']),
      data: json['data'] as Map<String, dynamic>?,
    );
    
    return model;
  }

  static String _parseLocalizedString(dynamic value) {
    if (value == null) {
      return '';
    }
    
    final localeService = LocaleService();
    final currentLang = localeService.currentLanguageCode;
    final fallbackLang = currentLang == 'tr' ? 'en' : 'tr';

    // Eğer Map ise (direkt JSON objesi)
    if (value is Map<String, dynamic>) {
      final currentLangText = value[currentLang]?.toString();
      final fallbackLangText = value[fallbackLang]?.toString();

      if (currentLangText != null && currentLangText.isNotEmpty) {
        return currentLangText;
      } else if (fallbackLangText != null && fallbackLangText.isNotEmpty) {
        return fallbackLangText;
      }
      
      // Diller bulunamadıysa ve map boş değilse ilk değeri döndür
      if (value.isNotEmpty) {
        for (var val in value.values) {
          if (val != null && val.toString().isNotEmpty) {
            return val.toString();
          }
        }
      }
      
      return '';
    }

    // Eğer String ise
    if (value is String) {
      final valueString = value.trim();
      
      // Özel durum: Backend'den boş JSON objesi string'i geliyorsa ("{}")
      if (valueString == '{}') {
        return '';
      }
      
      // JSON string formatında mı kontrol et: {"tr":"...","en":"..."}
      if (valueString.startsWith('{') && valueString.endsWith('}') && valueString.contains('"')) {
        try {
          final decoded = jsonDecode(valueString);
          if (decoded is Map<String, dynamic>) {
            final currentLangText = decoded[currentLang]?.toString();
            final fallbackLangText = decoded[fallbackLang]?.toString();

            if (currentLangText != null && currentLangText.isNotEmpty) {
              return currentLangText;
            } else if (fallbackLangText != null && fallbackLangText.isNotEmpty) {
              return fallbackLangText;
            }

            // Diller bulunamadıysa ve map boş değilse ilk değeri döndür
            if (decoded.isNotEmpty) {
              for (var val in decoded.values) {
                if (val != null && val.toString().isNotEmpty) {
                  return val.toString();
                }
              }
            }
            
            // Map boşsa veya geçerli değer yoksa boş string döndür
            // Bu sayede ekranda {} görünmesini engelleriz
            return '';
          }
        } catch (e) {
          // JSON parse hatası durumunda orijinal string'i döndür
          // Eğer parse hatası varsa ve string "{}" ise boş string döndür
          if (valueString == '{}') {
            return '';
          }
          return valueString;
        }
      }

      // Normal string ise direkt döndür
      // Ancak "{}" gibi boş JSON objesi string'lerini de boş string olarak döndür
      if (valueString == '{}') {
        return '';
      }
      
      return valueString;
    }

    // Diğer durumlar için toString() kullan
    return value.toString();
  }

  static NotificationType _parseNotificationType(dynamic type) {
    if (type == null) return NotificationType.other;

    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'appointment':
      case 'randevu':
        return NotificationType.appointment;
      case 'order':
      case 'sipariş':
        return NotificationType.order;
      case 'message':
      case 'mesaj':
        return NotificationType.message;
      case 'system':
      case 'sistem':
        return NotificationType.system;
      case 'promotion':
      case 'promosyon':
        return NotificationType.promotion;
      default:
        return NotificationType.other;
    }
  }

  static bool _parseIsRead(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();

    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic dateString) {
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'data': data,
    };
  }

  Notification toEntity() {
    return Notification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
      data: data,
    );
  }

  factory NotificationModel.fromEntity(Notification notification) {
    return NotificationModel(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
      data: notification.data,
    );
  }
}
