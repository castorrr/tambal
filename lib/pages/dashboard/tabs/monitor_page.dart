import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_recent_patient.dart'; // Import your RecentPatientCard widget
import 'package:tambal/services/realtime_database_service.dart'; // Import your RealtimeDatabaseService
import 'package:tambal/models/dispensing_log.dart'; // Import your DispensingLog model

class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently Dispensed', // Section title
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A86FF), // Same blue color
              ),
            ),
            const SizedBox(height: 16), // Spacing between title and cards

            // StreamBuilder to display dispensing logs
            Expanded(
              child: StreamBuilder<List<DispensingLog>>(
                stream: RealtimeDatabaseService().streamDispensingLogs(),
                builder: (context, snapshot) {
                  // Handle loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Handle error state
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Handle empty data state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No dispensing logs available.'));
                  }

                  final logs = snapshot.data!;

                  // Display list of dispensing logs
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return RecentPatientCard(
                        patientName: log.patientName,
                        day: log.day,
                        time: log.time,
                        medicineList: log.medicineList ?? [],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
