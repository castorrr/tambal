import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'custom_patient_dashboard_card.dart';
import '../models/patient.dart';
import 'package:provider/provider.dart';

class CustomDashboardPatient extends StatelessWidget {
  final Function(int) onTabChange;

  const CustomDashboardPatient({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Patient>>(
            stream: firestoreService.getPatientsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No patients available"));
              }

              List<Patient> patients = snapshot.data!;

              return FutureBuilder<Map<String, String>>(
                future: _fetchReadyForDispense(context, patients),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final readyForDispenseMap = snapshot.data!;

                  return SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        Patient patient = patients[index];
                        return CustomPatientDashboardCard(
                          name: patient.name,
                          gender: patient.gender,
                          readyForDispense:
                              readyForDispenseMap[patient.id] ?? "Loading...",
                          onTap: () =>
                              onTabChange(1), // Navigate to patients page
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _fetchReadyForDispense(
      BuildContext context, List<Patient> patients) async {
    Map<String, String> dispenseStatuses = {};
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    for (var patient in patients) {
      String latestDispense =
          await firestoreService.getLatestDispense(patient.id);
      dispenseStatuses[patient.id] = latestDispense;
    }

    return dispenseStatuses;
  }
}
