import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/utils/medicine_helper.dart';
import 'package:tambal/modals/modal_select_days.dart';
import 'package:tambal/modals/modal_select_medicine.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'dart:async';

class AddPatientModal extends StatefulWidget {
  final List<Map<String, String>> availableMedicines;
  final Patient? patient;

  const AddPatientModal({
    super.key,
    required this.availableMedicines,
    this.patient,
  });

  @override
  AddPatientModalState createState() => AddPatientModalState();
}

class AddPatientModalState extends State<AddPatientModal> {
  final Logger logger = Logger();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final MedicineHelper medicineHelper = MedicineHelper();
  final FirestoreService firestoreService = FirestoreService();
  final RealtimeDatabaseService realtimeDatabaseService =
      RealtimeDatabaseService();
  String selectedGender = 'Male';
  List<Map<String, dynamic>> schedules = [];
  List<bool> selectedDays = List.generate(7, (index) => false);
  bool everyDaySelected = false;
  List<String> fingerprintIDs = []; // List to store fingerprint IDs

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      nameController.text = widget.patient!.name;
      ageController.text = widget.patient!.age.toString();
      selectedGender = widget.patient!.gender;
      _loadSchedules(widget.patient!.id);
    }
  }

  Future<void> _loadSchedules(String patientId) async {
    try {
      final fetchedSchedules =
          await firestoreService.getSchedulesForPatient(patientId);
      setState(() {
        schedules = fetchedSchedules.map((schedule) {
          // Populate fingerprintIDs from the first schedule (since they should be the same for all)
          if (fingerprintIDs.isEmpty && schedule.fingerprintIDs.isNotEmpty) {
            fingerprintIDs = List<String>.from(schedule.fingerprintIDs);
          }
          return schedule.toMap();
        }).toList();
      });
    } catch (e) {
      logger.e('Failed to load schedules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.patient != null ? 'Edit Patient' : 'Add Patient'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 10),
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
            Column(
              children: schedules.map((schedule) {
                final index = schedules.indexOf(schedule);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      'Schedule ${index + 1}: ${schedule['days'].join(", ")} at ${schedule['time']}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicines: ${schedule['medicines'].map((m) => "Slot ${m['slot']}: ${m['name']} (x${m['quantity']})").join(", ")}',
                        ),
                        if (fingerprintIDs.isNotEmpty)
                          Text(
                            '${fingerprintIDs.length} ${fingerprintIDs.length == 1 ? "fingerprint added" : "fingerprints added"}',
                            style: const TextStyle(color: Colors.green),
                          ),
                      ],
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
            ElevatedButton(
              onPressed: _addSchedule,
              child: const Text('Add Schedule'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _extractFingerprint,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint),
                  SizedBox(width: 8),
                  Text('Extract Fingerprint'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
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

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
      return;
    }
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age as a number.')),
      );
      return;
    }
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one schedule.')),
      );
      return;
    }

    try {
      if (widget.patient != null) {
        // Update existing patient
        final data = {
          'name': name,
          'age': age,
          'gender': selectedGender,
        };
        await firestoreService.updatePatient(widget.patient!.id, data);

        // Delete all existing schedules first
        final existingSchedules =
            await firestoreService.getSchedulesForPatient(widget.patient!.id);
        for (final schedule in existingSchedules) {
          await firestoreService.deleteSchedule(schedule.id);
          await realtimeDatabaseService.deleteSchedule(schedule.id);
        }

        // Create all schedules as new
        for (final schedule in schedules) {
          final String scheduleId =
              firestoreService.generateUniqueId('schedules');
          final scheduleData = Schedule(
            id: scheduleId,
            patientId: widget.patient!.id,
            patientName: name,
            days: List<String>.from(schedule['days']),
            time: schedule['time'],
            medicines: List<Map<String, dynamic>>.from(schedule['medicines']),
            fingerprintIDs: fingerprintIDs,
          );

          await firestoreService.addSchedule(scheduleData);
          await realtimeDatabaseService.syncSchedule(scheduleData);
        }
      } else {
        // Add new patient (unchanged)
        final String patientId = firestoreService.generateUniqueId('patients');
        final patient = Patient(
          id: patientId,
          name: name,
          age: age,
          gender: selectedGender,
        );
        await firestoreService.addPatient(patient);

        for (final schedule in schedules) {
          final String scheduleId =
              firestoreService.generateUniqueId('schedules');
          final scheduleData = Schedule(
            id: scheduleId,
            patientId: patient.id,
            patientName: patient.name,
            days: List<String>.from(schedule['days']),
            time: schedule['time'],
            medicines: List<Map<String, dynamic>>.from(schedule['medicines']),
            fingerprintIDs: fingerprintIDs,
          );

          await firestoreService.addSchedule(scheduleData);
          await realtimeDatabaseService.syncSchedule(scheduleData);
        }
      }

      if (!mounted) return;
      logger.i('Patient and schedules saved successfully: $name');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      logger.e('Error saving patient and schedules: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save patient. Please try again.')),
      );
    }
  }

  void _addSchedule() async {
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

    if (!mounted) return;
    if (selectedDays.every((day) => !day) && !everyDaySelected) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted || time == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return ModalSelectMedicine(
          availableMedicines: widget.availableMedicines,
          onMedicinesSelected: (selectedMedicines) {
            if (selectedMedicines.isNotEmpty) {
              if (!mounted) return;
              setState(() {
                schedules.add({
                  'id': null,
                  'days': everyDaySelected ? ['Everyday'] : _getSelectedDays(),
                  'time': time.format(context),
                  'medicines': selectedMedicines,
                  'fingerprintIDs': [], // Initialize with an empty list
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

  void _extractFingerprint() async {
    bool fingerprintExtracted = false;
    Timer? timeoutTimer;

    // Show "Place your fingerprint" dialog with countdown
    int countdown = 3;
    _showFingerprintPromptDialog(countdown);

    // Countdown logic
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        countdown--;
      });

      if (countdown <= 0) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop(); // Dismiss the prompt dialog
        _showLoadingDialog(); // Show the loading dialog for fingerprint extraction
        _startFingerprintEnrollment(
            timeoutTimer, fingerprintExtracted); // Start fingerprint enrollment
      }
    });
  }

  void _startFingerprintEnrollment(
      Timer? timeoutTimer, bool fingerprintExtracted) async {
    // Set a timeout for 10 seconds
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!fingerprintExtracted && mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        realtimeDatabaseService.resetFingerprintCommand();
        logger.e('Failed to extract fingerprint within the timeout period.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to extract fingerprint. Please try again.')),
        );
      }
    });

    try {
      await realtimeDatabaseService.triggerFingerprintEnrollment();

      // Listen for the fingerprint ID result
      realtimeDatabaseService.listenForFingerprintID((String id) {
        if (!mounted || fingerprintExtracted) return; // Ensure `mounted` check

        fingerprintExtracted = true; // Set flag
        timeoutTimer?.cancel(); // Cancel the timeout timer

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
        }

        setState(() {
          fingerprintIDs.add(id); // Add the new fingerprint ID
        });

        logger.i('Fingerprint enrolled successfully with ID: $id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${fingerprintIDs.length} ${fingerprintIDs.length == 1 ? "fingerprint added" : "fingerprints added"}')),
          );
        }
      });
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        logger.e('Failed to extract fingerprint: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to extract fingerprint. Please try again.')),
        );
      }
    }
  }

  void _showFingerprintPromptDialog(int countdown) {
    if (!mounted) return; // Check if mounted before using `context`
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Text(
                'Place your finger on the scanner to enroll your fingerprint.\nExtracting fingerprint in $countdown...',
                textAlign: TextAlign.center,
              ),
            );
          },
        );
      },
    );
  }

  void _showLoadingDialog() {
    if (!mounted) return; // Check if mounted before using `context`
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Extracting fingerprint...'),
            ],
          ),
        );
      },
    );
  }
}
