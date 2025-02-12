import 'package:flutter/material.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'custom_alert_card.dart';

class AlertListWidget extends StatefulWidget {
  const AlertListWidget({super.key});

  @override
  State<AlertListWidget> createState() => _AlertListWidgetState();
}

class _AlertListWidgetState extends State<AlertListWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF3A86FF),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(
                Icons.add_alert_rounded,
                color: Colors.grey,
                size: 30.0,
              ),
            ],
          ),
        ),

        // Fetch Most Recent Patient Alert from Firestore
        SizedBox(
          height: 260, // Adjust height to fit content
          child: StreamBuilder<DispensingLog?>(
            stream: FirestoreService()
                .getMostRecentPatientAlert(), // 🔹 Fetch latest patient alert
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No recent alerts.'));
              }

              final alert = snapshot.data!; // 🔹 Most recent alert

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: CustomAlertCard(
                  key: ValueKey(
                      alert.day + alert.time), // 🔹 Unique key for each alert
                  patientName: alert.patientName,
                  missedMedicine: alert.medicineList.join(', '),
                  dateMissed: alert.day,
                  timeMissed: alert.time,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
