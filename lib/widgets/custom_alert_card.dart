import 'package:flutter/material.dart';

class CustomAlertCard extends StatelessWidget {
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String missedMedicine;
  final String dateMissed;
  final String timeMissed;

  const CustomAlertCard({
    super.key,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.missedMedicine,
    required this.dateMissed,
    required this.timeMissed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Details
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3A86FF),
                  child: Text(
                    patientName.split(' ').map((e) => e[0]).join(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: const Color(0xFF3A86FF)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gender: $patientGender   Age: $patientAge',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Missed Medicine Details
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Missed Medicine: $missedMedicine',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text('Date Missed: $dateMissed'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('Time Missed: $timeMissed'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
