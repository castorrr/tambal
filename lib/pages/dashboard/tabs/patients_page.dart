import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/widgets/custom_patient_list_card.dart';
import 'package:tambal/modals/modal_add_patient.dart';
import 'package:tambal/modals/modal_patient_schedules.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final realtimeDatabaseService =
        Provider.of<RealtimeDatabaseService>(context, listen: false);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 28, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Patients',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Patient>>(
                stream: firestoreService.getPatientsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No patients yet. Click the "+" button to add a patient.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final patients = snapshot.data!;
                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return CustomPatientListCard(
                        name: patient
                            .name, // Removed '??' since it's non-nullable
                        gender: patient.gender,
                        age: patient.age,
                        onEdit: () {
                          _showEditPatientModal(context, patient);
                        },
                        onDelete: () {
                          _showDeleteConfirmation(context, patient.id,
                              firestoreService, realtimeDatabaseService);
                        },
                        onDispense: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return PatientSchedulesModal(
                                patientId: patient.id,
                                patientName: patient
                                    .name, // Pass patient name for a better title
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPatientModal(context);
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add Patient',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Show the Add Patient Modal
  void _showAddPatientModal(BuildContext context) async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final fetchedMedicines =
          await firestoreService.getAvailableMedicinesWithSlots();

      List<Map<String, String>> availableMedicines =
          fetchedMedicines.map((medicine) {
        return {
          'slot': medicine['slot'].toString(),
          'name': medicine['name'].toString(),
        };
      }).toList();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddPatientModal(availableMedicines: availableMedicines);
          },
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medicines: $error')),
        );
      }
    }
  }

  /// Show the Edit Patient Modal
  void _showEditPatientModal(BuildContext context, Patient patient) async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final fetchedMedicines =
          await firestoreService.getAvailableMedicinesWithSlots();

      List<Map<String, String>> availableMedicines =
          fetchedMedicines.map((medicine) {
        return {
          'slot': medicine['slot'].toString(),
          'name': medicine['name'].toString(),
        };
      }).toList();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddPatientModal(
              availableMedicines: availableMedicines,
              patient: patient,
            );
          },
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medicines: $error')),
        );
      }
    }
  }

  /// Show the Delete Confirmation Dialog
  void _showDeleteConfirmation(
      BuildContext context,
      String patientId,
      FirestoreService firestoreService,
      RealtimeDatabaseService realtimeDatabaseService) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Patient'),
          content: const Text(
              'Are you sure you want to delete this patient and all their schedules?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await firestoreService.deletePatientAndSchedules(patientId);
        await realtimeDatabaseService.deleteSchedulesByPatient(patientId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Patient and associated schedules deleted successfully.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete patient: $e')),
          );
        }
      }
    }
  }
}
