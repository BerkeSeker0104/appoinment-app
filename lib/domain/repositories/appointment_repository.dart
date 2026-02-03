import '../../data/models/appointment_model.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getAppointments({
    String? startDate,
    String? companyId,
    String? customerId,
    String? status,
  });

  Future<List<AvailabilitySlot>> getAppointmentAvailability({
    required String companyId,
    required String date,
    String? userId,
  });

  Future<AppointmentModel> getAppointmentById(String appointmentId);

  Future<AppointmentModel> createAppointment(
    Map<String, dynamic> appointmentData,
  );

  Future<void> cancelAppointment(String appointmentId);

  Future<AppointmentModel> approveAppointment(String appointmentId);

  Future<AppointmentModel> startAppointment(
      String appointmentId, String approveCode);

  Future<AppointmentModel> completeAppointment(String appointmentId);
}

