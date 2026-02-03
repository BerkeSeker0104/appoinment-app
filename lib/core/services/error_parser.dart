import 'package:dio/dio.dart';

/// Central error parser for backend API error messages.
/// Parses different error formats and returns user-friendly Turkish error messages.
class ErrorParser {
  /// Parse DioException and return a user-friendly error message
  static Exception parseError(DioException error) {
    // Handle network/timeout errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
          'Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
        );
      case DioExceptionType.sendTimeout:
        return Exception(
          'Veri gönderimi zaman aşımına uğradı. Lütfen tekrar deneyin.',
        );
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Sunucudan yanıt alınamadı. Bağlantınızı kontrol edip tekrar deneyin.',
        );

      case DioExceptionType.cancel:
        return Exception('İstek iptal edildi.');

      case DioExceptionType.connectionError:
        return Exception('İnternet bağlantınızı kontrol edin.');

      case DioExceptionType.badCertificate:
        return Exception('Güvenlik sertifikası hatası.');

      case DioExceptionType.unknown:
        // Try to extract message from response if available
        if (error.response?.data != null) {
          final message = _extractErrorMessage(error.response!.data);
          if (message != null) {
            return Exception(message);
          }
        }
        return Exception('Bilinmeyen bir hata oluştu.');

      case DioExceptionType.badResponse:
        return _parseBadResponse(error);

      default:
        return Exception('Bilinmeyen bir hata oluştu.');
    }
  }

  /// Parse bad response errors (HTTP error status codes)
  static Exception _parseBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == null) {
      return Exception('Sunucudan hata yanıtı alınamadı.');
    }

    // Try to extract error message from response data
    String? errorMessage;
    if (data != null) {
      errorMessage = _extractErrorMessage(data);
    }

    // If no message found, use status code based fallback
    if (errorMessage == null || errorMessage.isEmpty) {
      errorMessage = _getFallbackMessage(statusCode);
    }

    return Exception(errorMessage);
  }

  /// Extract error message from response data
  /// Supports multiple formats:
  /// - { message: "..." }
  /// - { errors: [{ message: "...", field: "...", path: [...] }] }
  /// - { data: { message: "..." } }
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) {
      return null;
    }

    // Convert to Map if possible
    Map<String, dynamic>? dataMap = _asMap(responseData);
    if (dataMap == null) {
      // If it's a string, return it directly
      if (responseData is String && responseData.isNotEmpty) {
        return responseData;
      }
      return null;
    }

    // First, check for errors array (validation errors)
    final errorsMessage = _extractErrorsArray(dataMap);
    if (errorsMessage != null) {
      return errorsMessage;
    }

    // Check for direct message field
    if (dataMap.containsKey('message')) {
      final message = dataMap['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (message != null) {
        return message.toString();
      }
    }

    // Check for nested data.message
    if (dataMap.containsKey('data') && dataMap['data'] is Map<String, dynamic>) {
      final dataNode = dataMap['data'] as Map<String, dynamic>;
      if (dataNode.containsKey('message')) {
        final message = dataNode['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message != null) {
          return message.toString();
        }
      }
    }

    return null;
  }

  /// Extract error message from errors array
  /// Format: { errors: [{ message: "...", field: "...", path: [...] }] }
  static String? _extractErrorsArray(Map<String, dynamic> dataMap) {
    if (!dataMap.containsKey('errors')) {
      return null;
    }

    final errors = dataMap['errors'];
    if (errors is! List || errors.isEmpty) {
      return null;
    }

    // Get the first error
    final firstError = errors.first;
    if (firstError is! Map<String, dynamic>) {
      return null;
    }

    // Extract message
    String? errorMessage;
    if (firstError.containsKey('message')) {
      final message = firstError['message'];
      if (message is String && message.isNotEmpty) {
        errorMessage = message;
      } else if (message != null) {
        errorMessage = message.toString();
      }
    }

    // Handle special cases based on field/path
    if (firstError.containsKey('path') || firstError.containsKey('field')) {
      final pathOrField = firstError['path'] ?? firstError['field'];
      final pathString = _extractPathString(pathOrField);

      // Special handling for companyId errors
      if (pathString != null && pathString.contains('companyId')) {
        if (errorMessage != null &&
            (errorMessage.contains('length') ||
                errorMessage.contains('characters') ||
                errorMessage.contains('must be less than'))) {
          return 'Şube ID\'si çok uzun. Bu şubeye mesaj gönderilemiyor. Lütfen başka bir şubeyle iletişime geçin.';
        }
      }
    }

    // Return the error message if found
    return errorMessage;
  }

  /// Extract path string from path field (can be array or string)
  static String? _extractPathString(dynamic path) {
    if (path == null) {
      return null;
    }

    if (path is String) {
      return path;
    }

    if (path is List && path.isNotEmpty) {
      return path.first.toString();
    }

    return path.toString();
  }

  /// Get fallback message based on HTTP status code
  static String _getFallbackMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek. Lütfen bilgilerinizi kontrol edin.';
      case 401:
        return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case 404:
        return 'İstenen kaynak bulunamadı.';
      case 422:
        return 'Girilen bilgiler geçersiz.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      case 502:
        return 'Sunucu geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      case 503:
        return 'Servis geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Beklenmeyen bir hata oluştu (Status: $statusCode).';
    }
  }

  /// Convert dynamic value to Map<String, dynamic>
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

