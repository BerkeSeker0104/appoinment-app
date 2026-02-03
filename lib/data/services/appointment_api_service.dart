import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/appointment_model.dart';

class AppointmentApiService {
  final ApiClient _apiClient = ApiClient();

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

  List<dynamic> _extractAppointmentsList(Map<String, dynamic> data) {
    if (data['data'] is List) return data['data'] as List<dynamic>;
    if (data['appointments'] is List)
      return data['appointments'] as List<dynamic>;
    if (data['items'] is List) return data['items'] as List<dynamic>;
    if (data is List) return data as List<dynamic>;
    return [];
  }

  AppointmentModel _parseAppointmentResponse(Map<String, dynamic> data) {
    if (data['data'] is Map<String, dynamic>) {
      return AppointmentModel.fromJson(data['data']);
    }
    if (data['appointment'] is Map<String, dynamic>) {
      return AppointmentModel.fromJson(data['appointment']);
    }
    return AppointmentModel.fromJson(data);
  }

  // Get all appointments with optional filters (handles pagination automatically)
  Future<List<AppointmentModel>> getAppointments({
    String? startDate,
    String? companyId,
    String? customerId,
    String? status,
  }) async {
    final allAppointments = <AppointmentModel>[];
    int page = 1;
    bool hasMore = true;
    int safetyCounter = 0;
    const maxPages = 20; // Prevent infinite loops

    while (hasMore && safetyCounter < maxPages) {
      safetyCounter++;

    try {
        final queryParams = <String, dynamic>{
          'page': page,
          'limit': '100', // Request more items per page
        };
        
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
          // Some backends might expect snake_case
          queryParams['start_date'] = startDate;
      }
      if (companyId != null && companyId.isNotEmpty) {
        queryParams['companyId'] = companyId;
      }
      if (customerId != null && customerId.isNotEmpty) {
        queryParams['customerId'] = customerId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiConstants.appointments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = _asMap(response.data);
      final appointmentsList = _extractAppointmentsList(data);

        // Debug info for first page to check structure
        if (page == 1 && kDebugMode) {
           debugPrint('AppointmentApiService: First page fetched. Count: ${appointmentsList.length}');
           if (data.containsKey('pagination')) {
             debugPrint('Pagination Info: ${data['pagination']}');
           }
        }

        if (appointmentsList.isEmpty) {
          hasMore = false;
        } else {
          final pageAppointments = appointmentsList
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
              
          allAppointments.addAll(pageAppointments);

          // Pagination logic
          if (data['pagination'] is Map) {
            final pagination = data['pagination'];
            final totalPages = pagination['totalPages'];
            final currentPage = pagination['currentPage'];
            
            if (totalPages != null && currentPage != null) {
              final total = int.tryParse(totalPages.toString()) ?? 1;
              final current = int.tryParse(currentPage.toString()) ?? 1;
              
              if (current < total) {
                page++;
              } else {
                hasMore = false;
              }
            } else {
               // If valid list returned but no totalPages info, blindly try next page?
               // Safer to stop unless we are sure.
               // Assuming backend behaves correctly with pagination object.
               hasMore = false;
            }
          } else {
             // No pagination object, assume single page response
             hasMore = false;
          }
        }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
        // If 404 on first page, it usually means no data found
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
          if (page == 1) return [];
          break;
        }
        // Log error but return what we have so far
        debugPrint('AppointmentApiService: Error fetching page $page: $e');
        if (page == 1) throw Exception('Randevular yüklenirken hata oluştu: $e');
        break;
      }
    }
    
    if (kDebugMode) {
      debugPrint('AppointmentApiService: Total fetched appointments: ${allAppointments.length}');
    }

    return allAppointments;
  }

  Future<List<AvailabilitySlot>> getAppointmentAvailability({
    required String companyId,
    required String date,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'companyId': companyId,
        'date': date,
      };
      
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      
      final response = await _apiClient.get(
        ApiConstants.appointmentAvailability,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      
      List<dynamic> availabilityList;

      if (responseData is List) {
        availabilityList = responseData;
      } else {
        final data = _asMap(responseData);
        availabilityList = _extractAppointmentsList(data);
      }

      return availabilityList
          .map((json) => AvailabilitySlot.fromJson(_asMap(json)))
          .toList();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Uygunluk bilgileri alınırken hata oluştu: $e');
    }
  }

  // Get a specific appointment by ID
  Future<AppointmentModel> getAppointmentById(String appointmentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.appointments}/$appointmentId',
      );
      final data = _asMap(response.data);
      return _parseAppointmentResponse(data);
    } catch (e) {
      throw Exception('Randevu bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Create a new appointment
  Future<dynamic> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('=== APPOINTMENT CREATE REQUEST ===');
        debugPrint('URL: ${ApiConstants.baseUrl}${ApiConstants.appointments}');
        debugPrint('Body: ${jsonEncode(appointmentData)}');
      }

      final response = await _apiClient.post(
        ApiConstants.appointments,
        data: appointmentData,
      );

      if (kDebugMode) {
        debugPrint('=== APPOINTMENT CREATE RESPONSE ===');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Data: ${response.data}');
      }

      // Online ödeme için HTML içerik kontrolü
      if (response.data is String) {
        return response.data;
      }

      final data = _asMap(response.data);
      
      // Check for nested HTML content for 3D secure payments (online ödeme)
      if (data.containsKey('data') &&
          data['data'] is Map &&
          data['data'].containsKey('json') &&
          data['data']['json'] is Map &&
          data['data']['json'].containsKey('html')) {
        return data['data']['json']['html'] as String;
      }
      
      // Diğer HTML içerik formatları için kontrol
      if (data.containsKey('html')) {
        return data['html'] as String;
      }
      
      if (data.containsKey('data') && data['data'] is String) {
        // HTML içerik direkt data içinde olabilir
        final htmlContent = data['data'] as String;
        if (htmlContent.trim().startsWith('<')) {
          return htmlContent;
        }
      }
      
      // Online ödeme seçildiyse ve HTML içerik dönmediyse, AppointmentModel döndür
      // (Backend online ödeme için HTML döndürmüyor olabilir, bu durumda normal randevu oluşturulur)
      return _parseAppointmentResponse(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('=== APPOINTMENT CREATE ERROR ===');
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Randevu oluşturulurken hata oluştu: $e');
    }
  }

  // Cancel/Delete an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _apiClient.delete('${ApiConstants.appointments}/$appointmentId');
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        throw Exception('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
      }
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Randevu iptal özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        throw Exception('Bu randevuyu iptal etme yetkiniz bulunmuyor.');
      }
      throw Exception('Randevu iptal edilirken hata oluştu: $e');
    }
  }

  Future<AppointmentModel> approveAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.appointments}/approve/$appointmentId',
      );
      final data = _asMap(response.data);
      
      // Backend only returns {success: true, message: ...} without full appointment data
      // Always fetch full appointment details after successful approval
      if (data['success'] == true) {
        return await getAppointmentById(appointmentId);
      }
      
      // If backend returns full appointment data (id, customerName, etc.), try to parse it
      if (data['id'] != null || data['data'] != null || data['appointment'] != null) {
        try {
          final parsed = _parseAppointmentResponse(data);
          // Validate that parsed data has essential fields
          if (parsed.customerName.isNotEmpty && parsed.startDate.isNotEmpty) {
            return parsed;
          }
          // If essential fields are missing, fetch full data
          return await getAppointmentById(appointmentId);
        } catch (_) {
          return await getAppointmentById(appointmentId);
        }
      }
      
      // Fallback: fetch full appointment data
      return await getAppointmentById(appointmentId);
    } catch (e) {
      throw Exception('Randevu onaylanırken hata oluştu: $e');
    }
  }

  Future<AppointmentModel> startAppointment(
      String appointmentId, String approveCode) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.appointments}/start/$appointmentId',
        data: {'approveCode': approveCode},
      );
      final data = _asMap(response.data);
      if (data['id'] != null || data['success'] == true) {
        return await getAppointmentById(appointmentId);
      }
      return _parseAppointmentResponse(data);
    } catch (e) {
      throw Exception('Randevu başlatılırken hata oluştu: $e');
    }
  }

  Future<AppointmentModel> completeAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.appointments}/complete/$appointmentId',
      );
      final data = _asMap(response.data);
      if (data['id'] != null || data['success'] == true) {
        return await getAppointmentById(appointmentId);
      }
      return _parseAppointmentResponse(data);
    } catch (e) {
      throw Exception('Randevu tamamlanırken hata oluştu: $e');
    }
  }
}
