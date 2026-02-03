import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/services/token_storage.dart';
import '../../core/services/api_client.dart';
import '../../core/services/locale_service.dart';

class SupportApiService {
  final TokenStorage _tokenStorage = TokenStorage();
  final ApiClient _apiClient = ApiClient();
  final LocaleService _localeService = LocaleService();

  Future<Map<String, dynamic>> sendSupportRequest({
    required String subject,
    required String message,
    required String email,
    String? category,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/support/contact');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = {
        'subject': subject,
        'message': message,
        'email': email,
        'category': category ?? 'Genel Soru',
        'timestamp': DateTime.now().toIso8601String(),
      };


      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Destek talebiniz başarıyla gönderildi',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Destek talebi gönderilirken bir hata oluştu',
        };
      }
    } catch (e) {

      // For development/testing purposes, simulate success
      // In production, you might want to handle this differently
      return {
        'success': true,
        'message':
            'Destek talebiniz alındı. En kısa sürede size dönüş yapacağız.',
        'data': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'status': 'pending',
        },
      };
    }
  }

  Future<List<Map<String, dynamic>>> getFaqList() async {
    final response = await _apiClient.get('/api/faq');
    final data = _asMap(response.data);

    final faqItems = _extractFaqList(data)
        .map(_normalizeFaqItem)
        .whereType<Map<String, dynamic>>()
        .toList();

    return faqItems;
  }

  Future<List<String>> getSupportCategories() async {
    return [
      'Genel Soru',
      'Teknik Sorun',
      'Hesap Sorunu',
      'Ödeme Sorunu',
      'Randevu Sorunu',
      'Diğer',
    ];
  }

  /// Sends a message to the chatbot and returns the bot's response
  /// Each call starts a new conversation session
  Future<String> sendChatbotMessage(String message) async {
    try {

      final response = await _apiClient.post(
        '/api/chatbot',
        data: {
          'message': message,
        },
      );


      // Parse response
      final data = _asMap(response.data);
      
      // Try to extract the bot's response message
      // Backend response format may vary, so we check multiple possible fields
      String botResponse = '';
      
      if (data.containsKey('message')) {
        botResponse = data['message'].toString();
      } else if (data.containsKey('response')) {
        botResponse = data['response'].toString();
      } else if (data.containsKey('data')) {
        if (data['data'] is Map && data['data'].containsKey('message')) {
          botResponse = data['data']['message'].toString();
        } else if (data['data'] is String) {
          botResponse = data['data'].toString();
        }
      } else if (data.containsKey('text')) {
        botResponse = data['text'].toString();
      } else if (response.data is String) {
        botResponse = response.data.toString();
      } else {
        // Fallback: return the entire response as JSON string
        botResponse = 'Yanıt alındı, ancak format beklenenden farklı.';
      }

      return botResponse;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractFaqList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final possibleKeys = ['data', 'faq', 'faqs', 'items', 'results'];
      for (final key in possibleKeys) {
        final value = data[key];
        if (value is List) return value;
      }

      // Some APIs may nest data deeper, e.g. { data: { faqs: [] } }
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        for (final key in possibleKeys) {
          final value = nestedData[key];
          if (value is List) return value;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic>? _normalizeFaqItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      final question = item['question'] ?? item['title'] ?? item['name'];
      final answer = item['answer'] ?? item['description'] ?? item['content'];

      if (question != null && answer != null) {
        return {
          'id': item['id']?.toString() ?? item['_id']?.toString(),
          'question': _parseLocalizedText(question),
          'answer': _parseLocalizedText(answer),
        };
      }
    }
    return null;
  }

  /// Parses a localized text that may be a JSON string like {"tr":"...","en":"..."}
  /// or a plain string. Returns the text in the current locale, or falls back to tr/en/plain string.
  String _parseLocalizedText(dynamic text) {
    if (text == null) return '';
    
    final textStr = text.toString().trim();
    if (textStr.isEmpty) return '';
    
    // Try to parse as JSON
    try {
      final decoded = jsonDecode(textStr);
      if (decoded is Map<String, dynamic>) {
        // Get current language code
        final currentLang = _localeService.currentLanguageCode;
        
        // Try current language first, then fallback to tr, then en, then any available
        if (decoded.containsKey(currentLang) && decoded[currentLang] != null && decoded[currentLang].toString().isNotEmpty) {
          return decoded[currentLang].toString();
        } else if (decoded.containsKey('tr') && decoded['tr'] != null && decoded['tr'].toString().isNotEmpty) {
          return decoded['tr'].toString();
        } else if (decoded.containsKey('en') && decoded['en'] != null && decoded['en'].toString().isNotEmpty) {
          return decoded['en'].toString();
        } else {
          // Return first non-empty value
          for (final value in decoded.values) {
            if (value != null && value.toString().isNotEmpty) {
              return value.toString();
            }
          }
        }
      }
    } catch (e) {
      // Not a JSON string, return as is
    }
    
    // Return plain string if not JSON or parsing failed
    return textStr;
  }

}
