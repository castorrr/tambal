class DispensingLog {
  final String day;
  final String time;
  final String patientName;
  final List<dynamic>? medicineList;

  DispensingLog({
    required this.day,
    required this.time,
    required this.patientName,
    required this.medicineList,
  });

  factory DispensingLog.fromCombinedData({
    required String day,
    required String time,
    required String patientName,
    required List<dynamic> medicines,
  }) {
    return DispensingLog(
      day: day,
      time: time,
      patientName: patientName,
      medicineList: medicines.map((e) => e['name'] as String).toList(),
    );
  }
}
