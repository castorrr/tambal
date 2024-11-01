// File: medicine_page.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/widgets/custom_medicine_card.dart';
import 'package:tambal/modals/modal_add_medicine.dart';
import 'package:tambal/services/firestore_service.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger();
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

          // Determine which slots are taken
          List<int> takenSlots =
              medicines.map((medicine) => medicine.slot).toList();

          // Identify available slots (1, 2, 3 are the only valid slots)
          List<int> availableSlots =
              [1, 2, 3].where((slot) => !takenSlots.contains(slot)).toList();

          return Stack(
            children: [
              // Scrollable content
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: medicines.map((medicine) {
                  return CustomMedicineCard(
                    medicine: medicine,
                    onDispense: () {
                      logger.i('${medicine.name} dispensed');
                    },
                    onEdit: () {
                      logger.i('Edit ${medicine.name}');
                    },
                  );
                }).toList(),
              ),
              // Positioned FloatingActionButton
              Positioned(
                bottom: 16.0,
                right: 16.0,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Pass the available slots to the modal
                    showModalAddMedicine(context, availableSlots);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Medicine"),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
