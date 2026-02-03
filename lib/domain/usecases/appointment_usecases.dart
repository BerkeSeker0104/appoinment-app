import '../../data/models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentUseCases {
  final AppointmentRepository _appointmentRepository;

  AppointmentUseCases(this._appointmentRepository);

  Future<List<AvailabilitySlot>> getAppointmentAvailability({
    required String companyId,
    required String date,
    String? userId,
  }) async {
    if (companyId.isEmpty) {
      throw Exception('Şirket ID\'si zorunludur');
    }
    if (date.isEmpty) {
      throw Exception('Tarih bilgisi zorunludur');
    }

    return await _appointmentRepository.getAppointmentAvailability(
      companyId: companyId,
      date: date,
      userId: userId,
    );
  }

  Future<List<AppointmentModel>> fetchAppointments({
    String? startDate,
    String? companyId,
    String? customerId,
    String? status,
  }) async {
    return await _appointmentRepository.getAppointments(
      startDate: startDate,
      companyId: companyId,
      customerId: customerId,
      status: status,
    );
  }

  Future<AppointmentModel> getAppointmentDetail(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    return await _appointmentRepository.getAppointmentById(appointmentId);
  }

  Future<AppointmentModel> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    if (appointmentData.isEmpty) {
      throw Exception('Randevu bilgileri eksik');
    }

    return await _appointmentRepository.createAppointment(appointmentData);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    await _appointmentRepository.cancelAppointment(appointmentId);
  }

  Future<AppointmentModel> approveAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    return await _appointmentRepository.approveAppointment(appointmentId);
  }

  Future<AppointmentModel> startAppointment(
      String appointmentId, String approveCode) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }
    if (approveCode.isEmpty) {
      throw Exception('Onay kodu zorunludur');
    }
    return await _appointmentRepository.startAppointment(
        appointmentId, approveCode);
  }

  Future<AppointmentModel> completeAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      throw Exception('Randevu ID\'si zorunludur');
    }

    return await _appointmentRepository.completeAppointment(appointmentId);
  }
}

