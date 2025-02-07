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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap, // Trigger the callback when tapped
        child: ListTile(
          leading: const Icon(Icons.schedule, color: Colors.blue),
          title: Text(
            'Time: ${schedule.time}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Days: ${_formatDays(schedule.days)}'),
              const SizedBox(height: 4),
              Text(
                'Medicines: ${schedule.medicines.map((m) => m['name']).join(", ")}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to check if all days are selected and replace with "Everyday"
  String _formatDays(List<String> days) {
    const List<String> allDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // If all 7 days are selected, return "Everyday"
    if (days.length == 7 && days.toSet().containsAll(allDays)) {
      return "Everyday";
    }
    return days.join(", ");
  }
}
