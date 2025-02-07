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
  List<String> fingerprintIDs = [];
  bool isLoading = false; // Track the loading state
  bool isFingerprintLoading = false;
  bool _isLoadingDialogOpen = false; // Track if the loading dialog is open

// List to store fingerprint IDs

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

  @override
  void dispose() {
    // Dispose of the RealtimeDatabaseService listener
    realtimeDatabaseService.dispose();
    super.dispose();
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

  String _formatDays(List<String> days) {
    const List<String> allDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // If all seven days are selected, display "Everyday"
    if (days.length == 7 && days.toSet().containsAll(allDays)) {
      return "Everyday";
    }
    return days.join(", ");
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
                      'Schedule ${index + 1}: ${_formatDays(schedule['days'])} at ${schedule['time']}',
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
          onPressed:
              isLoading ? null : _savePatient, // Disable the button if loading
          child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Text('Save Patient'),
        ),
      ],
    );
  }

  Future<void> _savePatient() async {
    if (isLoading) return; // Prevent multiple clicks

    setState(() {
      isLoading = true;
    });

    // Show the loading dialog
    _showPatientLoadingDialog();

    final String name = nameController.text;
    final int? age = int.tryParse(ageController.text);

    if (name.isEmpty) {
      if (mounted) Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (age == null) {
      if (mounted) Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age as a number.')),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (schedules.isEmpty) {
      if (mounted) Navigator.of(context).pop(); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one schedule.')),
      );
      setState(() {
        isLoading = false;
      });
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
        // Add new patient
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

      if (mounted) {
        logger.i('Patient and schedules saved successfully: $name');
        Navigator.of(context).pop(); // Close the dialog
      }
    } catch (e) {
      logger.e('Error saving patient and schedules: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save patient. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        setState(() {
          isLoading = false;
        });
      }
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
                  // If everyday is selected, add all 7 days explicitly
                  'days': everyDaySelected
                      ? [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday'
                        ]
                      : _getSelectedDays(),
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

  void _extractFingerprint() {
    if (!mounted) return;
    _startFingerprintEnrollment(); // Directly starts the fingerprint enrollment
  }

  void _startFingerprintEnrollment() {
    if (!mounted || isFingerprintLoading) return;

    setState(() {
      isFingerprintLoading = true;
    });

    _showLoadingDialog(); // Show the loading dialog immediately

    // Timer for timeout in case fingerprint enrollment fails
    Timer? timeoutTimer = Timer(const Duration(seconds: 15), () async {
      if (mounted) {
        _closeLoadingDialog(); // Close the loading dialog
        setState(() {
          isFingerprintLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to extract fingerprint. Please try again.'),
          ),
        );
        await realtimeDatabaseService.resetFingerprintCommand();
      }
    });

    // Trigger fingerprint enrollment via ESP32/RTDB
    realtimeDatabaseService.triggerFingerprintEnrollment();

    // Listen for fingerprint ID updates
    realtimeDatabaseService.listenForFingerprintID((String id) async {
      if (!mounted || !isFingerprintLoading) return;

      // Stop the timeout timer as we have received a result
      timeoutTimer.cancel();

      // Reset fingerprint command to ensure the database is in a clean state
      await realtimeDatabaseService.resetFingerprintCommand();

      if (mounted) {
        _closeLoadingDialog(); // Close the loading dialog

        setState(() {
          isFingerprintLoading = false;
          fingerprintIDs.add(id); // Save the fingerprint ID
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fingerprint added successfully! Total fingerprints: ${fingerprintIDs.length}'),
          ),
        );
      }
    });
  }

  void _showLoadingDialog() {
    if (!mounted) return;
    _isLoadingDialogOpen = true; // Mark dialog as open
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

  void _closeLoadingDialog() {
    if (_isLoadingDialogOpen && mounted) {
      Navigator.of(context).pop(); // Pop the nearest dialog
      _isLoadingDialogOpen = false; // Mark dialog as closed
    }
  }

  void _showPatientLoadingDialog() {
    if (!mounted) return; // Check if mounted before using context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Saving patient data...'),
            ],
          ),
        );
      },
    );
  }
}
