import 'package:flutter/material.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'package:tambal/widgets/custom_alert_card.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder<List<DispensingLog>>(
        stream:
            FirestoreService().streamDispensingLogs(collectionName: "alerts"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No alerts available.'));
          }

          final alerts = snapshot.data!;

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              return CustomAlertCard(
                patientName: alert.patientName,
                missedMedicine: alert.scheduleType, // Convert list to string
                dateMissed: alert.date, // Assuming "day" is the missed date
                timeMissed: alert.time,
              );
            },
          );
        },
      ),
    );
  }
}
