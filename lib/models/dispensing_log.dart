class DispensingLog {
  final String date;
  final String time;
  final String patientId;
  final String patientName;
  final String scheduleType;
  final String medicine;
  final String source; // 🔹 "logging" or "alerts"

  DispensingLog({
    required this.date,
    required this.time,
    required this.patientId,
    required this.patientName,
    required this.scheduleType,
    required this.medicine,
    required this.source,
  });

  /// 🔹 Convert Firestore document data into a DispensingLog instance
  factory DispensingLog.fromFirestore(
      Map<String, dynamic> data, String source) {
    return DispensingLog(
      date: data['date'] ?? 'Unknown',
      time: data['time'] ?? 'Unknown',
      patientId: data['patientId'] ?? 'Unknown',
      patientName: data['patientName'] ?? 'Unknown',
      scheduleType: data['scheduleType'] != null
          ? data['scheduleType'].toString()
          : "Unknown",
      medicine: data['medicine'] ?? 'Unknown',
      source: source, // 🔹 Assign source dynamically
    );
  }

  /// 🔹 Convert a DispensingLog instance to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'time': time,
      'patientId': patientId,
      'patientName': patientName,
      'scheduleType': scheduleType,
      'medicine': medicine,
      'source': source,
    };
  }
}
