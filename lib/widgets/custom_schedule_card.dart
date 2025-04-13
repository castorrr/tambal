import 'package:flutter/material.dart';
import 'package:tambal/models/schedule.dart';

class CustomScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap; // Callback for click functionality

  const CustomScheduleCard({
    super.key,
    required this.schedule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // Trigger the callback when tapped
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Schedule Type
              Row(
                children: [
                  const Icon(Icons.event_note, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatScheduleType(schedule.scheduleType),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 🔹 Time
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Colors.black54, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    schedule.time,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 🔹 Medicines List
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _formatMedicineList(schedule.medicine),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Helper function to convert scheduleType (int) to readable text
  String _formatScheduleType(int scheduleType) {
    switch (scheduleType) {
      case 1:
        return "Breakfast";
      case 2:
        return "Lunch";
      case 3:
        return "Dinner";
      default:
        return "Unknown";
    }
  }

  // 🔹 Helper function to format medicines string into a readable list
  List<Widget> _formatMedicineList(String medicineString) {
    List<String> medicines = medicineString.split(','); // Split by comma
    return medicines.map((med) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          "• ${med.trim()}", // Bullet point + medicine info
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );
    }).toList();
  }
}
