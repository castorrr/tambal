class DispensingLog {
  final String day;
  final String time;
  final String patientName;
  final List<String> medicineList;

  DispensingLog({
    required this.day,
    required this.time,
    required this.patientName,
    required this.medicineList,
  });

  /// 🔹 Convert Firestore document data into a DispensingLog instance
  factory DispensingLog.fromFirestore(Map<String, dynamic> data) {
    return DispensingLog(
      day: data['day'] ?? 'Unknown',
      time: data['time'] ?? 'Unknown',
      patientName: data['patientId'] ?? 'Unknown',
      medicineList: (data['medicines'] as List<dynamic>?)
              ?.map((medicine) =>
                  medicine['medicineName']?.toString() ?? 'Unknown')
              .toList() ??
          [], // Default to empty list if medicines is null
    );
  }
}
