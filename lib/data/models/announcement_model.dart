import 'dart:convert';

class AnnouncementModel {
  final int id;
  final String titleJson;
  final String contentJson;
  final DateTime expiredDate;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.titleJson,
    required this.contentJson,
    required this.expiredDate,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      titleJson: json['title'] as String? ?? '',
      contentJson: json['content'] as String,
      expiredDate: DateTime.parse(json['expiredDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Unescapes and parses content string recursively.
  /// Handles various formats: plain string, escaped string, JSON string, double-escaped JSON.
  static String _unescapeContent(String content) {
    if (content.isEmpty) return content;
    
    String current = content.trim();
    const int maxDepth = 10;
    int depth = 0;
    
    while (depth < maxDepth) {
      try {
        final decoded = jsonDecode(current);
        
        if (decoded is String) {
          if (decoded.startsWith('"') && decoded.endsWith('"') && decoded.length > 2) {
            current = decoded;
            depth++;
            continue;
          }
          return decoded;
        }
        
        if (decoded is Map<String, dynamic>) {
          return jsonEncode(decoded);
        }
        
        return decoded.toString();
        
      } catch (e) {
        if (current.startsWith('"') && current.endsWith('"') && current.length >= 2) {
          current = current.substring(1, current.length - 1);
          current = current.replaceAll('\\"', '"');
          current = current.replaceAll('\\n', '\n');
          current = current.replaceAll('\\t', '\t');
          current = current.replaceAll('\\r', '\r');
          current = current.replaceAll('\\\\', '\\');
          depth++;
          continue;
        }
        
        return current;
      }
    }
    
    return current;
  }

  Map<String, dynamic> get _parsedContent {
    try {
      final unescapedContent = _unescapeContent(contentJson);
      
      try {
        final decoded = jsonDecode(unescapedContent);
        
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        
        if (decoded is String) {
          return {'tr': decoded, 'en': decoded};
        }
      } catch (_) {
        // JSON parse failed, use as plain string
      }
      
      if (unescapedContent.isNotEmpty) {
        return {'tr': unescapedContent, 'en': unescapedContent};
      }
      
      return {'tr': 'Geçersiz içerik', 'en': 'Invalid content'};
    } catch (e) {
      return {'tr': contentJson, 'en': contentJson};
    }
  }

  Map<String, dynamic> get _parsedTitle {
    try {
      final unescapedTitle = _unescapeContent(titleJson);
      
      try {
        final decoded = jsonDecode(unescapedTitle);
        
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        
        if (decoded is String) {
          return {'tr': decoded, 'en': decoded};
        }
      } catch (_) {
        // JSON parse failed, use as plain string
      }
      
      if (unescapedTitle.isNotEmpty) {
        return {'tr': unescapedTitle, 'en': unescapedTitle};
      }
      
      return {'tr': 'Başlık Yok', 'en': 'No Title'};
    } catch (e) {
      return {'tr': titleJson, 'en': titleJson};
    }
  }

  String getLocalizedHtmlContent(String localeCode) {
    final contentMap = _parsedContent;
    return contentMap[localeCode] ?? contentMap['tr'] ?? '';
  }

  String getLocalizedTitle(String localeCode) {
    final titleMap = _parsedTitle;
    return titleMap[localeCode] ?? titleMap['tr'] ?? '';
  }

  bool get isExpired {
    try {
      final now = DateTime.now().toUtc();
      final expiredDateUtc = expiredDate.isUtc ? expiredDate : expiredDate.toUtc();
      return now.isAfter(expiredDateUtc);
    } catch (e) {
      return true;
    }
  }

  String get formattedExpiredDate {
    return '${expiredDate.day.toString().padLeft(2, '0')}/${expiredDate.month.toString().padLeft(2, '0')}/${expiredDate.year}';
  }

  Duration? get timeUntilExpiration {
    final now = DateTime.now();
    if (expiredDate.isAfter(now)) {
      return expiredDate.difference(now);
    }
    return null;
  }
  AnnouncementModel copyWith({
    int? id,
    String? titleJson,
    String? contentJson,
    DateTime? expiredDate,
    DateTime? createdAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      titleJson: titleJson ?? this.titleJson,
      contentJson: contentJson ?? this.contentJson,
      expiredDate: expiredDate ?? this.expiredDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, titleJson: $titleJson, contentJson: $contentJson, expiredDate: $expiredDate, isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnouncementModel &&
        other.id == id &&
        other.titleJson == titleJson &&
        other.contentJson == contentJson &&
        other.expiredDate == expiredDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^ titleJson.hashCode ^ contentJson.hashCode ^ expiredDate.hashCode;
  }
}
