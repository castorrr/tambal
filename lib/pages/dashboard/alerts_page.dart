import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_alert_card.dart'; // Import the CustomAlertCard widget

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for alerts
    final List<Map<String, dynamic>> alerts = [
      {
        "patientName": "James Retubado",
        "patientGender": "Male",
        "patientAge": 45,
        "missedMedicine": "Paracetamol 500mg",
        "dateMissed": "2025-01-01",
        "timeMissed": "10:00 AM",
      },
      {
        "patientName": "Ronerr Villacarlos",
        "patientGender": "Female",
        "patientAge": 32,
        "missedMedicine": "Amoxicillin 250mg",
        "dateMissed": "2025-01-02",
        "timeMissed": "8:00 PM",
      },
      {
        "patientName": "Jule Quijano",
        "patientGender": "Female",
        "patientAge": 60,
        "missedMedicine": "Ibuprofen 200mg",
        "dateMissed": "2025-01-03",
        "timeMissed": "6:00 PM",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: Colors.white, // Replace with your desired color
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return CustomAlertCard(
            patientName: alert["patientName"],
            patientGender: alert["patientGender"],
            patientAge: alert["patientAge"],
            missedMedicine: alert["missedMedicine"],
            dateMissed: alert["dateMissed"],
            timeMissed: alert["timeMissed"],
          );
        },
      ),
    );
  }
}
