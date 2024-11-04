class Schedule {
  final String id; // Add an id property
  final String patientId;
  final String patientName;
  final List<String> days;
  final String time;
  final List<Map<String, dynamic>> medicines;
  final List<String> fingerprintIDs; // Change to a list of fingerprint IDs

  Schedule({
    required this.id, // Initialize id
    required this.patientId,
    required this.patientName,
    required this.days,
    required this.time,
    required this.medicines,
    this.fingerprintIDs = const [], // Default to an empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'days': days,
      'time': time,
      'medicines': medicines,
      'fingerprintIDs': fingerprintIDs, // Updated to use the list
    };
  }

  static Schedule fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      patientId: map['patientId'],
      patientName: map['patientName'],
      days: List<String>.from(map['days']),
      time: map['time'],
      medicines: List<Map<String, dynamic>>.from(map['medicines']),
      fingerprintIDs:
          List<String>.from(map['fingerprintIDs'] ?? []), // Handle null case
    );
  }
}
