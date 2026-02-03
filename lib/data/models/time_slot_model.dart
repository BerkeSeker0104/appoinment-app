enum SlotStatus {
  available,
  booked,
  blocked,
  break_time,
}

class TimeSlotModel {
  final String id;
  final String barberId;
  final DateTime date;
  final String timeSlot;
  final SlotStatus status;
  final String? appointmentId;
  final bool isWorkingHour;

  const TimeSlotModel({
    required this.id,
    required this.barberId,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.appointmentId,
    this.isWorkingHour = true,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String,
      barberId: json['barber_id'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as String,
      status: SlotStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => SlotStatus.available,
      ),
      appointmentId: json['appointment_id'] as String?,
      isWorkingHour: json['is_working_hour'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barber_id': barberId,
      'date': date.toIso8601String(),
      'time_slot': timeSlot,
      'status': status.name,
      'appointment_id': appointmentId,
      'is_working_hour': isWorkingHour,
    };
  }

  TimeSlotModel copyWith({
    String? id,
    String? barberId,
    DateTime? date,
    String? timeSlot,
    SlotStatus? status,
    String? appointmentId,
    bool? isWorkingHour,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      barberId: barberId ?? this.barberId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      isWorkingHour: isWorkingHour ?? this.isWorkingHour,
    );
  }

  bool get isAvailable => status == SlotStatus.available && isWorkingHour;
  
  bool get isBooked => status == SlotStatus.booked;
  
  bool get isBlocked => status == SlotStatus.blocked;

  String get statusText {
    switch (status) {
      case SlotStatus.available:
        return 'Müsait';
      case SlotStatus.booked:
        return 'Dolu';
      case SlotStatus.blocked:
        return 'Kapalı';
      case SlotStatus.break_time:
        return 'Mola';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlotModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimeSlotModel(id: $id, timeSlot: $timeSlot, status: $status)';
  }
}

class WorkingHours {
  final String barberId;
  final Map<int, DaySchedule> weeklySchedule; // 1-7 (Monday-Sunday)

  const WorkingHours({
    required this.barberId,
    required this.weeklySchedule,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    final scheduleMap = <int, DaySchedule>{};
    final schedule = json['weekly_schedule'] as Map<String, dynamic>;
    
    schedule.forEach((day, scheduleJson) {
      scheduleMap[int.parse(day)] = DaySchedule.fromJson(scheduleJson);
    });

    return WorkingHours(
      barberId: json['barber_id'] as String,
      weeklySchedule: scheduleMap,
    );
  }

  Map<String, dynamic> toJson() {
    final scheduleMap = <String, dynamic>{};
    weeklySchedule.forEach((day, schedule) {
      scheduleMap[day.toString()] = schedule.toJson();
    });

    return {
      'barber_id': barberId,
      'weekly_schedule': scheduleMap,
    };
  }

  DaySchedule? getScheduleForDay(int weekday) {
    return weeklySchedule[weekday];
  }

  bool isWorkingDay(int weekday) {
    final schedule = getScheduleForDay(weekday);
    return schedule?.isWorking ?? false;
  }
}

class DaySchedule {
  final bool isWorking;
  final String? startTime; // "09:00"
  final String? endTime; // "18:00"
  final List<BreakTime> breaks;

  const DaySchedule({
    required this.isWorking,
    this.startTime,
    this.endTime,
    this.breaks = const [],
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isWorking: json['is_working'] as bool,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      breaks: (json['breaks'] as List?)
          ?.map((breakJson) => BreakTime.fromJson(breakJson))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_working': isWorking,
      'start_time': startTime,
      'end_time': endTime,
      'breaks': breaks.map((breakTime) => breakTime.toJson()).toList(),
    };
  }
}

class BreakTime {
  final String startTime;
  final String endTime;
  final String description;

  const BreakTime({
    required this.startTime,
    required this.endTime,
    required this.description,
  });

  factory BreakTime.fromJson(Map<String, dynamic> json) {
    return BreakTime(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'description': description,
    };
  }
}
