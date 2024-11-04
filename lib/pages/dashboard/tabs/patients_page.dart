import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/modals/modal_add_patient.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/widgets/custom_patient_list_card.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

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
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No patients yet.'),
                    );
                  }

                  final patients = snapshot.data!;
                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return CustomPatientListCard(
                        name: patient.name,
                        gender: patient.gender,
                        age: patient.age,
                        onEdit: () {
                          // Handle edit action
                          _showEditPatientModal(context, patient);
                        },
                        onDelete: () async {
                          // Show a confirmation dialog before deleting
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Patient'),
                                content: const Text(
                                    'Are you sure you want to delete this patient and all their schedules?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Proceed with deletion if the user confirmed
                          if (confirmDelete == true) {
                            try {
                              await firestoreService
                                  .deletePatientAndSchedules(patient.id);

                              // Check if the widget is still mounted before using context
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Patient and associated schedules deleted successfully.'),
                                ),
                              );
                            } catch (e) {
                              // Check if the widget is still mounted before using context
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete patient: $e'),
                                ),
                              );
                            }
                          }
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
        onPressed: () async {
          try {
            // Fetch the available medicines with slots
            List<Map<String, dynamic>> fetchedMedicines =
                await firestoreService.getAvailableMedicinesWithSlots();

            // Convert the data to List<Map<String, String>>
            List<Map<String, String>> availableMedicines = fetchedMedicines
                .map((medicine) => {
                      'slot': medicine['slot'].toString(),
                      'name': medicine['name'].toString(),
                    })
                .toList();

            // Check if the widget is still mounted before using context
            if (!context.mounted) return;

            _showAddPatientModal(context, availableMedicines);
          } catch (error) {
            // Check if the widget is still mounted before using context
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load medicines: $error')),
            );
          }
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add Patient',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPatientModal(
      BuildContext context, List<Map<String, String>> availableMedicines) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPatientModal(availableMedicines: availableMedicines);
      },
    );
  }

  void _showEditPatientModal(BuildContext context, Patient patient) {
    // Show modal for editing patient details
    // You can create and use a separate modal for editing or reuse the AddPatientModal with pre-filled data
  }
}
