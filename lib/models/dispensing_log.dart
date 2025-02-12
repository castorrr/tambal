class DispensingLog {
  final String day;
  final String time;
  final String patientName;
  final List<String> medicineList;
  final String source; // 🔹 "logging" or "alerts"

  DispensingLog({
    required this.day,
    required this.time,
    required this.patientName,
    required this.medicineList,
    required this.source, // 🔹 Add source field
  });

  /// 🔹 Convert Firestore document data into a DispensingLog instance
  factory DispensingLog.fromFirestore(
      Map<String, dynamic> data, String source) {
    return DispensingLog(
      day: data['day'] ?? 'Unknown',
      time: data['time'] ?? 'Unknown',
      patientName: data['patientName'] ??
          'Unknown', // Fix: Use patientName instead of patientId
      medicineList: (data['medicines'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((medicine) =>
                  medicine['medicineName']?.toString() ?? 'Unknown')
              .toList() ??
          [], // Default to empty list if medicines is null
      source: source, // 🔹 Assign source dynamically
    );
  }
}
