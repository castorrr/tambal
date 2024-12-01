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
              Text('Days: ${schedule.days.join(", ")}'),
              const SizedBox(height: 4),
              Text(
                  'Medicines: ${schedule.medicines.map((m) => m['name']).join(", ")}'),
            ],
          ),
        ),
      ),
    );
  }
}
