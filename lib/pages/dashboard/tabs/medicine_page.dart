import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/widgets/custom_medicine_card.dart';
import 'package:tambal/modals/modal_add_edit_medicine.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/dispense_service.dart';
import '../../../services/realtime_database_service.dart';

class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});

  @override
  MedicinePageState createState() => MedicinePageState();
}

class MedicinePageState extends State<MedicinePage> {
  final Logger logger = Logger();
  List<int> availableSlots = [];

  Future<void> _handleDispense(Medicine medicine) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text("Dispensing Medicine"),
        content: Text("Please wait..."),
      ),
    );

    bool success = false;
    try {
      final dispenseService = DispenseService(RealtimeDatabaseService());
      success = await dispenseService.dispenseMedicine(medicine.slot);
    } catch (error) {
      logger.e('Failed to set dispense: $error');
    }

    if (mounted) {
      Navigator.of(context).pop();

      if (success) {
        logger.i('Medicine dispensed successfully from slot ${medicine.slot}.');
        _showSnackBar('Medicine dispensed successfully.');
      } else {
        logger.e('Unsuccessful dispensing. Slot ${medicine.slot} reset to 0.');
        _showSnackBar('Unsuccessful dispensing. Please try again.');
      }
    }
  }

  Future<void> _handleDelete(Medicine medicine) async {
    bool? confirmDelete;
    if (mounted) {
      confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Delete Medicine"),
            content: Text("Are you sure you want to delete ${medicine.name}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete"),
              ),
            ],
          );
        },
      );
    }

    if (confirmDelete == true && mounted) {
      try {
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteMedicine(medicine.id);

        if (mounted) {
          logger.i('Medicine ${medicine.name} deleted successfully.');
          _showSnackBar('Medicine deleted successfully.');
        }
      } catch (error) {
        if (mounted) {
          logger.e('Failed to delete medicine: $error');
          _showSnackBar('Failed to delete medicine. Please try again.');
        }
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: StreamBuilder<List<Medicine>>(
        stream: firestoreService.getMedicines(),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No medicine yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            );
          }

          final List<Medicine> medicines = snapshot.data!;
          medicines.sort((a, b) => a.slot.compareTo(b.slot));
          List<int> takenSlots =
              medicines.map((medicine) => medicine.slot).toList();
          availableSlots =
              [1, 2, 3].where((slot) => !takenSlots.contains(slot)).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: medicines.map((medicine) {
              return CustomMedicineCard(
                medicine: medicine,
                onDispense: () => _handleDispense(medicine),
                onEdit: () {
                  showModalAddOrEditMedicine(context, availableSlots,
                      medicine: medicine);
                },
                onDelete: () => _handleDelete(medicine),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Medicine>>(
        stream: firestoreService.getMedicines(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.length < 3) {
            return FloatingActionButton.extended(
              onPressed: () {
                if (mounted) {
                  showModalAddOrEditMedicine(context, availableSlots);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Medicine"),
              backgroundColor: Theme.of(context).primaryColor,
            );
          }
          return const SizedBox.shrink(); // Hide FAB if condition not met
        },
      ),
    );
  }
}
