// File: modals/add_patient_modal.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/utils/medicine_helper.dart';
import 'package:tambal/modals/modal_select_days.dart';
import 'package:tambal/modals/modal_select_medicine.dart';
import 'package:tambal/services/firestore_service.dart';

class AddPatientModal extends StatefulWidget {
  final List<Map<String, String>> availableMedicines;

  const AddPatientModal({super.key, required this.availableMedicines});

  @override
  AddPatientModalState createState() => AddPatientModalState();
}

class AddPatientModalState extends State<AddPatientModal> {
  final Logger logger = Logger();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final MedicineHelper medicineHelper = MedicineHelper();
  final FirestoreService firestoreService = FirestoreService();
  String selectedGender = 'Male';
  List<Map<String, dynamic>> schedules = [];
  List<bool> selectedDays = List.generate(7, (index) => false);
  bool everyDaySelected = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Patient'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Input
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),

            // Age Input
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 10),

            // Gender Selection
            DropdownButtonFormField<String>(
              value: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            const SizedBox(height: 20),

            // List of Schedules
            Column(
              children: schedules.map((schedule) {
                final index = schedules.indexOf(schedule);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      'Schedule ${index + 1}: ${schedule['days'].join(", ")} at ${schedule['time']}',
                    ),
                    subtitle: Text(
                      'Medicines: ${schedule['medicines'].map((m) => "Slot ${m['slot']}: ${m['name']} (x${m['quantity']})").join(", ")}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          schedules.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Button to Add New Schedule
            ElevatedButton(
              onPressed: _addSchedule,
              child: const Text('Add Schedule'),
            ),
            const SizedBox(height: 20),

            // Fingerprint Button (Placeholder)
            ElevatedButton(
              onPressed: _extractFingerprint,
              child: const Text('Extract Fingerprint'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the modal
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePatient,
          child: const Text('Save Patient'),
        ),
      ],
    );
  }

  Future<void> _savePatient() async {
    final String name = nameController.text;
    final int? age = int.tryParse(ageController.text);

    // Check for valid name and age input
    if (name.isEmpty) {
      // Show error if name is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
      return;
    }
    if (age == null) {
      // Show error if age is not a valid integer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age as a number.')),
      );
      return;
    }
    if (schedules.isEmpty) {
      // Show error if there are no schedules added
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one schedule.')),
      );
      return;
    }

    // Generate a unique ID for the patient using Firestore
    final String patientId = firestoreService.generateUniqueId('patients');
    final patient = Patient(
      id: patientId,
      name: name,
      age: age,
      gender: selectedGender,
      fingerprintData: null, // Placeholder for fingerprint data
    );

    try {
      // Perform asynchronous operations
      await firestoreService.addPatient(patient);

      // Save each schedule asynchronously
      for (var schedule in schedules) {
        final scheduleData = Schedule(
          patientId: patient.id,
          patientName: patient.name,
          days: List<String>.from(schedule['days']),
          time: schedule['time'],
          medicines: List<Map<String, dynamic>>.from(schedule['medicines']),
        );
        await firestoreService.addSchedule(scheduleData);
      }

      // Use BuildContext synchronously after async operations
      if (!mounted) return;
      logger.i('Patient and schedules saved successfully: $name');
      Navigator.of(context).pop(); // Close the modal on success
    } catch (e) {
      // Use BuildContext synchronously before using it
      if (!mounted) return;
      logger.e('Error saving patient and schedules: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save patient. Please try again.')),
      );
    }
  }

  void _addSchedule() async {
    // Open the ModalSelectDays dialog
    await showDialog(
      context: context,
      builder: (context) {
        return ModalSelectDays(
          selectedDays: selectedDays,
          everyDaySelected: everyDaySelected,
          onSelectionDone: (isEveryDaySelected, selectedDaysCheck) {
            setState(() {
              everyDaySelected = isEveryDaySelected;
              selectedDays = selectedDaysCheck;
            });
          },
        );
      },
    );

    if (!mounted) return; // Check if the widget is still mounted
    if (selectedDays.every((day) => !day) && !everyDaySelected) return;

    // Open the time picker
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted) return; // Check if the widget is still mounted
    if (time == null) return; // Early return if time picker is canceled

    // Open the ModalSelectMedicine dialog
    await showDialog(
      context: context,
      builder: (context) {
        return ModalSelectMedicine(
          availableMedicines: widget.availableMedicines,
          onMedicinesSelected: (selectedMedicines) {
            if (selectedMedicines.isNotEmpty) {
              if (!mounted) return; // Check if the widget is still mounted
              setState(() {
                schedules.add({
                  'days': everyDaySelected ? ['Everyday'] : _getSelectedDays(),
                  'time': time.format(context),
                  'medicines': selectedMedicines,
                });
              });
            }
          },
        );
      },
    );
  }

  List<String> _getSelectedDays() {
    const List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return daysOfWeek
        .asMap()
        .entries
        .where((entry) => selectedDays[entry.key])
        .map((entry) => entry.value)
        .toList();
  }

  void _extractFingerprint() {
    logger.i('Fingerprint extraction logic to be implemented.');
  }
}
