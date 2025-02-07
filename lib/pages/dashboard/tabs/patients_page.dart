import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/widgets/custom_patient_list_card.dart';
import 'package:tambal/modals/modal_add_patient.dart';
import 'package:tambal/modals/modal_patient_information.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  PatientsPageState createState() => PatientsPageState();
}

class PatientsPageState extends State<PatientsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final realtimeDatabaseService =
        Provider.of<RealtimeDatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context)
            .scaffoldBackgroundColor, // Matches the background color
        elevation: 0, // Removes shadow for a seamless look
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search patients...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : Row(
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
        actions: [
          IconButton(
            padding: const EdgeInsets.only(
                right: 8.0), // Adjust this value as needed
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                  List<Patient> patients = snapshot.data!;
                  patients.sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                  if (_isSearching && _searchController.text.isNotEmpty) {
                    patients = patients
                        .where((patient) => patient.name
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return CustomPatientListCard(
                        name: patient.name,
                        gender: patient.gender,
                        age: patient.age,
                        onEdit: () {
                          _showEditPatientModal(context, patient);
                        },
                        onDelete: () {
                          _showDeleteConfirmation(
                            context,
                            patient.id,
                            firestoreService,
                            realtimeDatabaseService,
                          );
                        },
                        onTap: () {
                          // Show Patient Information Modal
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => PatientInformationModal(
                              patientName: patient.name,
                              patientAge: patient.age,
                              patientGender: patient.gender,
                              patientId: patient.id,
                            ),
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
    RealtimeDatabaseService realtimeDatabaseService,
  ) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Patient'),
          content: const Text(
            'Are you sure you want to delete this patient and all their schedules?',
          ),
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
                'Patient and associated schedules deleted successfully.',
              ),
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
