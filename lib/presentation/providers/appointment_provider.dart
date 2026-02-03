import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/service_model.dart';
import '../../data/services/appointment_api_service.dart';
import '../../data/services/branch_api_service.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/services/app_lifecycle_service.dart';

class AppointmentProvider extends ChangeNotifier implements LoadingStateResettable {
  final AppointmentApiService _appointmentService = AppointmentApiService();
  final BranchApiService _branchService = BranchApiService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());

  // State Variables
  BranchModel? _branch;
  bool _isLoadingBranch = false;
  
  List<String> _bookedSlots = [];
  // Locally blocked slots (discovered via error messages)
  final Set<String> _locallyBlockedSlots = {};
  
  Map<String, String> _slotEndTimes = {};
  bool _isLoadingBookedSlots = false;
  bool _isCreatingAppointment = false;

  // Constants
  static const int _slotIntervalMinutes = 30;
  static const int _minDurationMinutes = 30;
  static const String _weekdayOpenTime = '09:00';
  static const String _weekdayCloseTime = '18:00';
  static const String _saturdayOpenTime = '10:00';
  static const String _saturdayCloseTime = '16:00';

  // Getters
  BranchModel? get branch => _branch;
  bool get isLoadingBranch => _isLoadingBranch;
  bool get isLoadingBookedSlots => _isLoadingBookedSlots;
  bool get isCreatingAppointment => _isCreatingAppointment;
  List<String> get bookedSlots => [..._bookedSlots, ..._locallyBlockedSlots];

  // Branch Yükleme
  Future<void> loadBranch(String barberId, {BranchModel? initialBranch}) async {
    if (_isLoadingBranch) return;

    if (initialBranch != null) {
      _branch = initialBranch;
      notifyListeners();
      return;
    }

    _isLoadingBranch = true;
    notifyListeners();

    try {
      _branch = await _branchService.getBranch(barberId);
    } catch (e) {
      debugPrint('Error loading branch: $e');
    } finally {
      _isLoadingBranch = false;
      notifyListeners();
    }
  }

  // Randevuları Yükleme ve Slotları Hesaplama
  Future<void> loadBookedSlots(String barberId, DateTime selectedDate, {String? userId}) async {
    if (_isLoadingBookedSlots) return;

    _isLoadingBookedSlots = true;
    _bookedSlots.clear();
    _locallyBlockedSlots.clear(); // Clear local blocks on refresh
    _slotEndTimes.clear();
    notifyListeners();

    try {
      // Backend formatına uygun tarih (YYYY-MM-DD)
      final formattedDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final bookedSlotsSet = <String>{};
      final slotEndTimesMap = <String, String>{};

      // 1. Yeni availability endpoint'inden dolu slotları çekelim
      final availabilitySlots =
          await _appointmentService.getAppointmentAvailability(
        companyId: barberId,
        date: formattedDate,
        userId: userId,
      );

      if (availabilitySlots.isNotEmpty) {
        // Availability API dolu slot döndürdü - bu slotları işaretle
        for (final slot in availabilitySlots) {
          final startMinutes = _timeToMinutes(slot.normalizedStartHour);
          final endMinutes = _timeToMinutes(slot.normalizedFinishHour);
          if (startMinutes == null || endMinutes == null) continue;

          final actualStartMinutes = _roundDownToSlot(startMinutes);
          _markAppointmentSlots(
            actualStartMinutes,
            endMinutes,
            bookedSlotsSet,
            slotEndTimesMap,
          );
        }
      } else if (userId != null && userId.isNotEmpty) {
        // Availability API boş döndü VE userId belirtilmiş
        // Bu demek ki: bu çalışan bu tarihte tamamen müsait, hiç randevusu yok
        // bookedSlotsSet boş kalacak = tüm slotlar müsait
      } else {
        // userId verilmedi - fallback olarak eski mantığı kullan (company-wide)
        final appointments = await _appointmentService.getAppointments(
          startDate: formattedDate,
          companyId: barberId,
        );

        // İptal edilmemiş randevuları filtrele
        final activeAppointments = appointments
            .where((a) => a.status != AppointmentStatus.cancelled)
            .toList();

        for (final appointment in activeAppointments) {
          if (!_isAppointmentDateMatch(appointment.startDate, selectedDate)) {
            continue;
          }

          final startHour = appointment.startHour;
          if (startHour.isEmpty) continue;

          final normalizedStartHour = _normalizeTime(startHour);
          final startMinutes = _timeToMinutes(normalizedStartHour);
          if (startMinutes == null) continue;

          // Slotları hesapla
          final actualStartMinutes = _roundDownToSlot(startMinutes);
          final totalDurationMinutes = _roundUpToSlotInterval(
              _calculateDuration(appointment, normalizedStartHour, actualStartMinutes));
          final endMinutes = _calculateEndMinutes(
              appointment, actualStartMinutes, totalDurationMinutes);

          _markAppointmentSlots(
              actualStartMinutes, endMinutes, bookedSlotsSet, slotEndTimesMap);
        }
      }

      _bookedSlots = bookedSlotsSet.toList();
      _slotEndTimes = slotEndTimesMap;
      
    } catch (e) {
      debugPrint('Error loading booked slots: $e');
    } finally {
      _isLoadingBookedSlots = false;
      notifyListeners();
    }
  }

  void markSlotAsUnavailable(String slot) {
    if (!_bookedSlots.contains(slot) && !_locallyBlockedSlots.contains(slot)) {
      _locallyBlockedSlots.add(slot);
      notifyListeners();
    }
  }

  // Randevu Oluşturma
  Future<void> createAppointment({
    required String barberId,
    required DateTime selectedDate,
    required String selectedTimeSlot,
    required List<ServiceModel> selectedServices,
    String? userId,
    required String paidType,
    String? cardNumber,
    String? cardExpirationMonth,
    String? cardExpirationYear,
    String? cardCvc,
    required Future<void> Function(String? htmlContent) onSuccess,
    required Function(String error) onError,
  }) async {
    if (_isCreatingAppointment) return;

    // Validasyonlar
    if (isOutsideWorkingHours(selectedTimeSlot, selectedDate)) {
      onError('Seçilen saat çalışma saatleri dışında. Lütfen müsait bir saat seçin.');
      return;
    }

    if (isPastTime(selectedTimeSlot, selectedDate)) {
      onError('Geçmiş saatlere randevu alınamaz. Lütfen gelecek bir saat seçin.');
      return;
    }

    _isCreatingAppointment = true;
    notifyListeners();

    try {
      final user = await _authUseCases.getCurrentUser();
      if (user == null) throw Exception('Kullanıcı bilgileri alınamadı');

      final formattedDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final nameParts = user.name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : user.name;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final userPhone = user.phone?.trim() ?? '';
      String formattedPhone = '';
      if (userPhone.isNotEmpty) {
        try {
          formattedPhone = _formatPhoneWithCountryCode(userPhone);
        } catch (_) {
          formattedPhone = '';
        }
      }

      final servicesPayload = selectedServices.map((service) {
        return {
          'id': service.id.toString(),
          'price': service.price.toStringAsFixed(0),
        };
      }).toList();

      final adjustedStartHour = _adjustStartHourForBackend(selectedTimeSlot);

      final appointmentData = <String, dynamic>{
        'companyId': barberId.toString(),
        'customerName': firstName,
        'customerLastName': lastName,
        'customerPhone': formattedPhone,
        'startDate': formattedDate,
        'startHour': adjustedStartHour,
        'services': servicesPayload,
        'paidType': paidType,
      };

      // userId sadece null ve boş değilse ekle
      if (userId != null && userId.isNotEmpty) {
        appointmentData['userId'] = userId;
      }

      // Online ödeme seçildiyse kart bilgileri gönderilir
      if (paidType == 'online') {
        if (cardNumber == null || cardNumber.isEmpty ||
            cardExpirationMonth == null || cardExpirationMonth.isEmpty ||
            cardExpirationYear == null || cardExpirationYear.isEmpty ||
            cardCvc == null || cardCvc.isEmpty) {
          onError('Online ödeme için kart bilgileri eksik. Lütfen tüm alanları doldurun.');
          return;
        }
        appointmentData['cardNumber'] = cardNumber;
        appointmentData['cardExpirationMonth'] = cardExpirationMonth;
        appointmentData['cardExpirationYear'] = cardExpirationYear;
        appointmentData['cardCvc'] = cardCvc;
      }
      // creditCard ve cash fiziki mağazada ödeme için - kart bilgileri gönderilmiyor

      final result = await _appointmentService.createAppointment(appointmentData);

      if (result is String) {
        await onSuccess(result);
      } else {
        await onSuccess(null);
      }
    } catch (e) {
      onError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isCreatingAppointment = false;
      notifyListeners();
    }
  }

  // --- Helper Methods (Public for UI usage) ---

  List<String> getAvailableTimeSlots(DateTime selectedDate, {bool is24Hours = false}) {
    final workingHours = getWorkingHoursForDate(selectedDate);
    String? openTime;
    String? closeTime;

    if (is24Hours) {
       // 7/24 logic is handled in generating slots
    } else if (workingHours != null) {
      openTime = workingHours['openTime'];
      closeTime = workingHours['closeTime'];
    }

    final timeSlots = _generateTimeSlots(
      is24Hours: is24Hours,
      openTime: openTime,
      closeTime: closeTime,
    );

    return timeSlots.where((timeSlot) {
      if (isPastTime(timeSlot, selectedDate)) return false;
      if (is24Hours) return true;
      if (isOutsideWorkingHours(timeSlot, selectedDate)) return false;
      return true;
    }).toList();
  }

  bool isSlotBooked(String slot) {
    return _bookedSlots.contains(slot);
  }

  bool isEndTimeSlot(String slot) {
    return _slotEndTimes.values.contains(slot);
  }

  bool isSlotAvailableForDuration(String startSlot, int totalDuration, DateTime selectedDate) {
    final slotsNeeded = (totalDuration / _slotIntervalMinutes).ceil();
    final startMinutes = _timeToMinutes(startSlot);
    if (startMinutes == null) return false;

    int currentMinutes = startMinutes;

    for (int i = 0; i < slotsNeeded; i++) {
      final slotTime = _minutesToTime(currentMinutes);

      if (isSlotBooked(slotTime) && !isEndTimeSlot(slotTime)) {
        return false;
      }

      if (isOutsideWorkingHours(slotTime, selectedDate)) {
        return false;
      }

      currentMinutes += _slotIntervalMinutes;
    }

    return true;
  }

  bool isPastTime(String timeSlot, DateTime selectedDate) {
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1]),
    );

    if (selectedDate.day == now.day &&
        selectedDate.month == now.month &&
        selectedDate.year == now.year) {
      return selectedDateTime.isBefore(now);
    }
    return false;
  }

  bool isOutsideWorkingHours(String timeSlot, DateTime selectedDate) {
    final workingHours = getWorkingHoursForDate(selectedDate);
    if (workingHours == null) return true;

    if (workingHours['isAlwaysOpen'] == 'true') return false;

    final timeParts = timeSlot.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final timeInMinutes = hour * 60 + minute;

    final openTimeParts = workingHours['openTime']!.split(':');
    final openHour = int.parse(openTimeParts[0]);
    final openMinute = int.parse(openTimeParts[1]);
    final openTimeInMinutes = openHour * 60 + openMinute;

    final closeTimeParts = workingHours['closeTime']!.split(':');
    final closeHour = int.parse(closeTimeParts[0]);
    final closeMinute = int.parse(closeTimeParts[1]);
    final closeTimeInMinutes = closeHour * 60 + closeMinute;

    return timeInMinutes < openTimeInMinutes ||
        timeInMinutes >= closeTimeInMinutes;
  }

  Map<String, String>? getWorkingHoursForDate(DateTime date) {
    if (_branch != null && _branch!.workingHours.isNotEmpty) {
      if (_branch!.workingHours.containsKey('all') &&
          _branch!.workingHours['all'] == '7/24 Açık') {
        return {
          'openTime': '00:00',
          'closeTime': '23:59',
          'isAlwaysOpen': 'true'
        };
      }

      final weekday = date.weekday;
      final dayMap = {
        1: 'monday', 2: 'tuesday', 3: 'wednesday', 4: 'thursday',
        5: 'friday', 6: 'saturday', 7: 'sunday',
      };

      final dayName = dayMap[weekday];
      if (dayName == null) return null;

      final hours = _branch!.workingHours[dayName];
      if (hours == null || hours.trim().isEmpty) return null;

      final normalized = hours.trim().toLowerCase();
      if (normalized.contains('kapalı') || normalized == 'closed') {
        return null;
      }

      String normalizedHours = hours.trim();
      List<String> parts;

      if (normalizedHours.contains(' - ')) {
        parts = normalizedHours.split(' - ');
      } else if (normalizedHours.contains('-')) {
        parts = normalizedHours.split('-');
      } else {
        return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
      }

      if (parts.length >= 2) {
        return {
          'openTime': parts[0].trim(),
          'closeTime': parts[1].trim(),
        };
      }
    }

    // Fallback logic
    final weekday = date.weekday;
    switch (weekday) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
      case DateTime.friday:
        return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
      case DateTime.saturday:
        return {'openTime': _saturdayOpenTime, 'closeTime': _saturdayCloseTime};
      default:
        return null;
    }
  }

  // --- Private Helper Methods ---

  List<String> _generateTimeSlots(
      {bool is24Hours = false, String? openTime, String? closeTime}) {
    if (is24Hours) {
      final slots = <String>[];
      for (int minutes = 0; minutes < 24 * 60; minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    } else if (openTime != null && closeTime != null) {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');
      final openTotalMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeTotalMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      if (closeTotalMinutes <= openTotalMinutes) return [];

      final slots = <String>[];
      var currentMinutes = openTotalMinutes;

      while (currentMinutes < closeTotalMinutes) {
        slots.add(_minutesToTime(currentMinutes));
        currentMinutes += _slotIntervalMinutes;
      }
      return slots;
    } else {
      // Default slots
      final slots = <String>[];
      final startMinutes = 9 * 60;
      final endMinutes = 17 * 60 + 30;
      for (int minutes = startMinutes; minutes < endMinutes; minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    }
  }

  String _normalizeTime(String time) {
    if (!time.contains(':')) return time;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  int? _timeToMinutes(String time) {
    final parts = _normalizeTime(time).split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _roundDownToSlot(int minutes) {
    final minute = minutes % 60;
    final roundedMinute = (minute ~/ _slotIntervalMinutes) * _slotIntervalMinutes;
    return (minutes ~/ 60) * 60 + roundedMinute;
  }

  int _roundUpToSlotInterval(int minutes) {
    if (minutes < _minDurationMinutes) return _minDurationMinutes;
    return ((minutes + _slotIntervalMinutes - 1) ~/ _slotIntervalMinutes) *
        _slotIntervalMinutes;
  }

  String _adjustStartHourForBackend(String selectedHour) {
    // Backend artık slot sınırlarında başlayıp biten randevuları destekliyor.
    // Seçilen saati olduğu gibi gönderiyoruz, sadece formatını normalize ediyoruz.
    return _normalizeTime(selectedHour);
  }

  String _formatPhoneWithCountryCode(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[+\s-]'), '');
    if (cleanPhone.length < 10) throw Exception('Geçersiz telefon numarası formatı');
    if (cleanPhone.startsWith('90') && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(2);
    }
    return '90 $cleanPhone';
  }

  bool _isAppointmentDateMatch(String appointmentDateStr, DateTime selectedDate) {
    if (appointmentDateStr.isEmpty) return false;
    try {
      String datePart = appointmentDateStr.trim();
      
      // Clean up time parts
      if (datePart.contains('T')) {
        datePart = datePart.split('T')[0];
      } else if (datePart.contains(' ')) {
        datePart = datePart.split(' ')[0];
      }

      // Try parsing standard formats
      int? year, month, day;

      if (datePart.contains('-')) {
        final parts = datePart.split('-');
        if (parts.length == 3) {
           if (parts[0].length == 4) { // YYYY-MM-DD
             year = int.tryParse(parts[0]);
             month = int.tryParse(parts[1]);
             day = int.tryParse(parts[2]);
           } else if (parts[2].length == 4) { // DD-MM-YYYY or MM-DD-YYYY
             // Try to determine if first part is day or month. 
             // Usually it's DD-MM-YYYY in this region.
             year = int.tryParse(parts[2]);
             month = int.tryParse(parts[1]);
             day = int.tryParse(parts[0]);
           }
        }
      } else if (datePart.contains('/')) {
         final parts = datePart.split('/');
         if (parts.length == 3) {
            // Assume DD/MM/YYYY or MM/DD/YYYY based on context? 
            // Let's assume DD/MM/YYYY for now given the region (TR)
            if (parts[2].length == 4) {
               year = int.tryParse(parts[2]);
               month = int.tryParse(parts[1]);
               day = int.tryParse(parts[0]);
            }
         }
      }

      if (year != null && month != null && day != null) {
             return year == selectedDate.year &&
                    month == selectedDate.month &&
                    day == selectedDate.day;
           }
      
      // Fallback: try DateTime.parse
      final parsed = DateTime.tryParse(datePart);
      if (parsed != null) {
        return parsed.year == selectedDate.year &&
               parsed.month == selectedDate.month &&
               parsed.day == selectedDate.day;
      }
      
      return false; 
    } catch (e) {
      debugPrint('Date parse error: $e');
      return false;
    }
  }

  int _calculateDuration(AppointmentModel appointment, String normalizedStartHour, int actualStartMinutes) {
    // 1. Backend'den finishHour (HH:MM) geliyorsa onu kullan
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final finishMinutes = _timeToMinutes(_normalizeTime(appointment.finishHour!));
      final startMinutes = _timeToMinutes(normalizedStartHour);
      if (finishMinutes != null && startMinutes != null) {
        final duration = finishMinutes - startMinutes;
        if (duration > 0) return duration;
      }
    }
    
    // 2. Yoksa servis sürelerini topla
    return appointment.services.fold<int>(
      0, (sum, service) => sum + (service.durationMinutes ?? _minDurationMinutes));
  }

  int _calculateEndMinutes(AppointmentModel appointment, int currentMinutes, int totalDurationMinutes) {
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final finishMinutes = _timeToMinutes(_normalizeTime(appointment.finishHour!));
      if (finishMinutes != null) return finishMinutes;
    }
    return currentMinutes + totalDurationMinutes;
  }

  void _markAppointmentSlots(int startMinutes, int endMinutes, Set<String> bookedSlotsSet, Map<String, String> slotEndTimesMap) {
    final endTime = _minutesToTime(endMinutes);
    int currentMinutes = startMinutes;
    String? lastSlot;

    if (endMinutes <= currentMinutes) {
      final slotTime = _minutesToTime(currentMinutes);
      bookedSlotsSet.add(slotTime);
      lastSlot = slotTime;
    } else {
      while (currentMinutes < endMinutes) {
        final slotTime = _minutesToTime(currentMinutes);
        bookedSlotsSet.add(slotTime);
        lastSlot = slotTime;
        currentMinutes += _slotIntervalMinutes;
      }
    }

    if (lastSlot != null) {
      slotEndTimesMap[lastSlot] = endTime;
    }
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoadingBranch || _isLoadingBookedSlots || _isCreatingAppointment) {
      _isLoadingBranch = false;
      _isLoadingBookedSlots = false;
      _isCreatingAppointment = false;
      notifyListeners();
    }
  }
}
