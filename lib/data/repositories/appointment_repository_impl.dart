import '../models/appointment_model.dart';
import '../services/appointment_api_service.dart';
import '../../domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentApiService _appointmentApiService = AppointmentApiService();

  @override
  Future<List<AppointmentModel>> getAppointments({
    String? startDate,
    String? companyId,
    String? customerId,
    String? status,
  }) async {
    try {
      return await _appointmentApiService.getAppointments(
        startDate: startDate,
        companyId: companyId,
        customerId: customerId,
        status: status,
      );
    } catch (e) {
      throw Exception('Randevular yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<List<AvailabilitySlot>> getAppointmentAvailability({
    required String companyId,
    required String date,
    String? userId,
  }) async {
    try {
      return await _appointmentApiService.getAppointmentAvailability(
        companyId: companyId,
        date: date,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Uygunluk bilgileri alınırken hata oluştu: $e');
    }
  }

  @override
  Future<AppointmentModel> getAppointmentById(String appointmentId) async {
    try {
      return await _appointmentApiService.getAppointmentById(appointmentId);
    } catch (e) {
      throw Exception('Randevu bilgileri yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<AppointmentModel> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      return await _appointmentApiService.createAppointment(appointmentData);
    } catch (e) {
      throw Exception('Randevu oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentApiService.cancelAppointment(appointmentId);
    } catch (e) {
      throw Exception('Randevu iptal edilirken hata oluştu: $e');
    }
  }

  @override
  Future<AppointmentModel> approveAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    try {
      return await _appointmentApiService.approveAppointment(appointmentId);
    } catch (e) {
      throw Exception('Randevu onaylanırken hata oluştu: $e');
    }
  }

  @override
  Future<AppointmentModel> startAppointment(
      String appointmentId, String approveCode) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    try {
      return await _appointmentApiService.startAppointment(
          appointmentId, approveCode);
    } catch (e) {
      throw Exception('Randevu başlatılırken hata oluştu: $e');
    }
  }

  @override
  Future<AppointmentModel> completeAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    try {
      return await _appointmentApiService.completeAppointment(appointmentId);
    } catch (e) {
      throw Exception('Randevu tamamlanırken hata oluştu: $e');
    }
  }
}

