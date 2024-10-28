import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_recent_patient.dart'; // Import RecentPatientCard widget

class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample recent patient data
    final List<Map<String, dynamic>> recentPatients = [
      {
        'patientName': 'Mrs. Mary T. Smith',
        'patientGender': 'Female',
        'patientAge': 49,
        'medicineDispensed': 'Aspirin',
      },
      {
        'patientName': 'Mr. James Retubado',
        'patientGender': 'Male',
        'patientAge': 52,
        'medicineDispensed': 'Metformin',
      },
      {
        'patientName': 'Mr. Ronerr Villacarlos',
        'patientGender': 'Male',
        'patientAge': 61,
        'medicineDispensed': 'Atorvastatin',
      },
    ];

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

            // Display recent patient cards
            Expanded(
              child: ListView.builder(
                itemCount: recentPatients.length,
                itemBuilder: (context, index) {
                  final patient = recentPatients[index];
                  return RecentPatientCard(
                    patientName: patient['patientName'],
                    patientGender: patient['patientGender'],
                    patientAge: patient['patientAge'],
                    medicineDispensed: patient['medicineDispensed'],
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
