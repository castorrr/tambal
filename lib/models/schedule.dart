class Schedule {
  final String id;
  final String patientId;
  final String patientName;
  final String time;
  final int slot;
  final String fingerprintIDs; // Now a string instead of a list
  final String medicine;
  final int scheduleType;
  final int latestModified;

  Schedule({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.time,
    required this.slot,
    this.fingerprintIDs = "", // Default to empty string
    required this.medicine,
    required this.scheduleType,
    required this.latestModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'time': time,
      'slot': slot,
      'fingerprintIDs': fingerprintIDs, // Store as a string
      'medicine': medicine,
      'scheduleType': scheduleType,
      'latestModified': latestModified,
    };
  }

  static Schedule fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      time: map['time'] as String,
      slot: map['slot'] as int,
      fingerprintIDs: map['fingerprintIDs'] ?? "", // Default to empty string
      medicine: map['medicine'] as String,
      scheduleType: map['scheduleType'] as int,
      latestModified: map['latestModified'] as int,
    );
  }
}
