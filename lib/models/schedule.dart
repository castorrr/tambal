// File: models/schedule.dart

class Schedule {
  final String patientId;
  final String patientName;
  final List<String> days; // Days of the week, or "Everyday"
  final String time; // Time in 24-hour format
  final List<Map<String, dynamic>>
      medicines; // Medicines with slot, name, and quantity

  Schedule({
    required this.patientId,
    required this.patientName,
    required this.days,
    required this.time,
    required this.medicines,
  });

  // Method to convert a Schedule object to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'days': days,
      'time': time,
      'medicines': medicines,
    };
  }

  // Method to create a Schedule object from a map (from Firestore)
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      patientId: map['patientId'],
      patientName: map['patientName'],
      days: List<String>.from(map['days']),
      time: map['time'],
      medicines: List<Map<String, dynamic>>.from(map['medicines']),
    );
  }
}
