import 'package:flutter/material.dart';
import 'custom_recent_patient.dart'; // Import the recent patient card

class RecentPatientListWidget extends StatelessWidget {
  const RecentPatientListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.all(16.0), // Keep const here since it's static
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(
                  Icons.local_activity_rounded, // Medicine icon
                  color: Colors.grey,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),

        // Patient List (Using ListView or Column for multiple cards)
        ListView(
          shrinkWrap: true, // Ensure the ListView only takes as much space as needed
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the ListView
          children: const [
            RecentPatientCard(
              patientName: 'Mr. James Retubado',
              patientGender: 'Male',
              patientAge: 52,
              medicineDispensed: 'Neozep', // Keep the medicine dispensed field
            ),
            RecentPatientCard(
              patientName: 'Mr. Ronerr Villacarlos',
              patientGender: 'Male',
              patientAge: 61,
              medicineDispensed: 'Tiki-Tiki', // Keep the medicine dispensed field
            ),
          ],
        ),
      ],
    );
  }
}
