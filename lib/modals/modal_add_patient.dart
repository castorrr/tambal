import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/modals/modal_select_days.dart';
import 'package:tambal/modals/modal_select_medicine.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'dart:async';

class AddPatientModal extends StatefulWidget {
  final Patient? patient;

  const AddPatientModal({
    super.key,
    this.patient,
  });

  @override
  AddPatientModalState createState() => AddPatientModalState();
}

class AddPatientModalState extends State<AddPatientModal> {
  final Logger logger = Logger();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  final RealtimeDatabaseService realtimeDatabaseService =
      RealtimeDatabaseService();

  List<int> availablePatientSlots = [1, 2, 3, 4, 5]; // Slots 1-5
  String? selectedPatientSlot; // Holds assigned patient number
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
    _fetchTakenPatientSlots();

    if (widget.patient != null) {
      nameController.text = widget.patient!.name;
      ageController.text = widget.patient!.age.toString();
      selectedGender = widget.patient!.gender;
      _loadSchedules(widget.patient!.id);
      selectedPatientSlot = widget.patient!.slot.toString();
    }
  }

  @override
  void dispose() {
    // Dispose of the RealtimeDatabaseService listener
    realtimeDatabaseService.dispose();
    super.dispose();
  }

  Future<void> _fetchTakenPatientSlots() async {
    final List<Patient> patients = await firestoreService.getAllPatients();
    final List<int> takenSlots =
        patients.map((p) => p.slot).cast<int>().toList();

    setState(() {
      availablePatientSlots =
          [1, 2, 3, 4, 5].where((slot) => !takenSlots.contains(slot)).toList();

      // Auto-select first available slot if adding a new patient
      if (widget.patient == null && availablePatientSlots.isNotEmpty) {
        selectedPatientSlot = availablePatientSlots.first.toString();
      }
    });
  }

  Future<void> _loadSchedules(String patientId) async {
    try {
      final fetchedSchedules =
          await firestoreService.getSchedulesForPatient(patientId);

      setState(() {
        schedules = fetchedSchedules.map((schedule) {
          // Convert fingerprintIDs from a comma-separated string to a List<String>
          if (fingerprintIDs.isEmpty && schedule.fingerprintIDs.isNotEmpty) {
            fingerprintIDs = schedule.fingerprintIDs
                .split(",")
                .where((id) => id.isNotEmpty)
                .toList();
          }
          return schedule.toMap();
        }).toList();
      });
    } catch (e) {
      logger.e('Failed to load schedules: $e');
    }
  }

  String _getScheduleType(int scheduleType) {
    switch (scheduleType) {
      case 1:
        return "Breakfast";
      case 2:
        return "Lunch";
      case 3:
        return "Dinner";
      default:
        return "Unknown";
    }
  }

  int _compareScheduleType(String typeA, String typeB) {
    const order = ['breakfast', 'lunch', 'dinner'];
    return order.indexOf(typeA).compareTo(order.indexOf(typeB));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sortedSchedules = List.from(schedules);
    sortedSchedules.sort((a, b) => _compareScheduleType(
        _getScheduleType(a['scheduleType']).toLowerCase(),
        _getScheduleType(b['scheduleType']).toLowerCase()));

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
            const SizedBox(height: 10),
            widget.patient == null
                ? (availablePatientSlots.isNotEmpty
                    ? DropdownButtonFormField<String>(
                        value: selectedPatientSlot,
                        decoration: const InputDecoration(
                            labelText: 'Patient Number (Slot)'),
                        items: availablePatientSlots.map((int value) {
                          return DropdownMenuItem<String>(
                            value: value.toString(),
                            child: Text('Patient No. $value'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPatientSlot = newValue;
                          });
                        },
                      )
                    : const Text('No patient slots available'))
                : Text('Patient No.: ${widget.patient!.slot}',
                    style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Column(
              children: sortedSchedules.map((schedule) {
                final index = schedules.indexOf(schedule);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                        '${_getScheduleType(schedule['scheduleType'])} at ${schedule['time']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medicines: ${schedule['medicine']}',
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

    _showPatientLoadingDialog(); // Show the loading dialog

    final String name = nameController.text;
    final int? age = int.tryParse(ageController.text);
    final int slot =
        int.tryParse(selectedPatientSlot ?? '') ?? -1; // Ensure slot is an int

    if (name.isEmpty || age == null || slot == -1) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly.')),
      );
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
      String patientId;

      if (widget.patient != null) {
        patientId = widget.patient!.id; // ✅ Update existing patient

        final data = {
          'name': name,
          'age': age,
          'gender': selectedGender,
          'slot': slot, // ✅ Always an int
        };

        await firestoreService.updatePatient(patientId, data);

        final existingSchedules =
            await firestoreService.getSchedulesForPatient(patientId);
        for (final schedule in existingSchedules) {
          await firestoreService.deleteSchedule(schedule.id);
          await realtimeDatabaseService.deleteSchedule(schedule.id);
        }
      } else {
        patientId = firestoreService.generateUniqueId('patients');

        final patient = Patient(
          id: patientId,
          name: name,
          age: age,
          gender: selectedGender,
          slot: slot,
        );

        await firestoreService.addPatient(patient);
      }

      // ✅ Convert `fingerprintIDs` from List to String
      final String fingerprintString = fingerprintIDs.join(",");

      for (final schedule in schedules) {
        final String scheduleId =
            firestoreService.generateUniqueId('schedules');

        final scheduleData = Schedule(
          id: scheduleId,
          patientId: patientId,
          patientName: name,
          time: schedule['time'] ?? '00:00',
          slot:
              int.tryParse(schedule['slot'].toString()) ?? 0, // ✅ Always an int
          medicine: schedule['medicine'] ?? 'N/A', // ✅ Always a String
          fingerprintIDs:
              fingerprintString, // ✅ Stored as a comma-separated string
          scheduleType: schedule['scheduleType'] as int, // ✅ Always an int
        );

        await firestoreService.addSchedule(scheduleData);
        await realtimeDatabaseService.syncSchedule(scheduleData);
      }

      if (mounted) {
        logger.i('✅ Patient and schedules saved successfully: $name');
        Navigator.of(context).pop(); // Close the dialog
      }
    } catch (e, stackTrace) {
      logger.e('⛔ Error saving patient and schedules: $e\n$stackTrace');
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
    if (!mounted) return;

    // Define schedule type mappings
    const Map<int, String> scheduleTypes = {
      1: 'Breakfast',
      2: 'Lunch',
      3: 'Dinner'
    };

    // Get already selected schedule types
    List<int> existingTypes =
        schedules.map((schedule) => schedule['scheduleType'] as int).toList();

    // Get available schedule options
    List<int> availableTypes = scheduleTypes.keys
        .where((type) => !existingTypes.contains(type))
        .toList();

    if (availableTypes.isEmpty) {
      if (!mounted) return; // Ensure widget is still active
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You can only have one schedule for Breakfast, Lunch, and Dinner.'),
        ),
      );
      return;
    }

    // Show schedule type selection dialog
    int? selectedScheduleType = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        int tempSelectedType = availableTypes.first;
        return AlertDialog(
          title: const Text('Select Schedule Type'),
          content: DropdownButtonFormField<int>(
            value: tempSelectedType,
            items: availableTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(scheduleTypes[type]!),
              );
            }).toList(),
            onChanged: (value) {
              tempSelectedType = value!;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(tempSelectedType),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedScheduleType == null) return;

    // Proceed with selecting days and time
    setState(() {
      everyDaySelected = true;
      selectedDays = List.generate(7, (index) => true);
    });

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return ModalSelectDays(
          selectedDays: selectedDays,
          everyDaySelected: everyDaySelected,
          onSelectionDone: (isEveryDaySelected, selectedDaysCheck) {
            if (!mounted) return;
            setState(() {
              everyDaySelected = isEveryDaySelected;
              selectedDays = selectedDaysCheck;
            });
          },
        );
      },
    );

    if (!mounted || (selectedDays.every((day) => !day) && !everyDaySelected)) {
      return;
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted || time == null) return;

    // Show modal to enter medicine details
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return ModalSelectMedicine(
          onMedicinesSelected: (String formattedMedicine) {
            // ✅ Expect a String instead of List<Map<String, dynamic>>
            if (!mounted) return;
            if (formattedMedicine.isNotEmpty) {
              setState(() {
                schedules.add({
                  'id': null,
                  'scheduleType':
                      selectedScheduleType, // ✅ Ensure it stores schedule type
                  'time': time.format(context), // ✅ Store formatted time
                  'slot': selectedPatientSlot, // ✅ Store patient slot
                  'fingerprintIDs': [], // ✅ Default empty list
                  'medicine':
                      formattedMedicine, // ✅ Now stored as a properly formatted String
                });
              });
            }
          },
        );
      },
    );
  }

  void _extractFingerprint() {
    if (!mounted) return;
    _startFingerprintEnrollment();
  }

  void _startFingerprintEnrollment() {
    if (!mounted || isFingerprintLoading) return;

    setState(() {
      isFingerprintLoading = true;
    });

    _showLoadingDialog(); // Show the loading dialog

    Timer? timeoutTimer = Timer(const Duration(seconds: 15), () async {
      if (mounted) {
        _closeLoadingDialog();
        setState(() {
          isFingerprintLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'Failed to extract fingerprint. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        await realtimeDatabaseService.resetFingerprintCommand();
      }
    });

    // Trigger fingerprint enrollment via ESP32/RTDB
    realtimeDatabaseService.triggerFingerprintEnrollment();

    // Listen for fingerprint ID updates
    realtimeDatabaseService.listenForFingerprintID((String id) async {
      if (!mounted || !isFingerprintLoading) return;

      timeoutTimer.cancel(); // Stop timeout timer

      await realtimeDatabaseService
          .resetFingerprintCommand(); // Reset fingerprint command

      if (mounted) {
        _closeLoadingDialog(); // Close the loading dialog

        setState(() {
          isFingerprintLoading = false;

          // ✅ Append new fingerprint ID to the string (comma-separated)
          if (fingerprintIDs.isEmpty) {
            fingerprintIDs.add(id);
          } else {
            fingerprintIDs.add(id);
          }
        });

        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fingerprint added successfully! Current: ${fingerprintIDs.join(",")}'),
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
