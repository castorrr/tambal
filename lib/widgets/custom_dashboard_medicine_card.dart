import 'package:flutter/material.dart';
import 'package:tambal/services/firestore_service.dart'; // Import your Firestore service
import 'package:tambal/widgets/custom_medicine_pill.dart'; // Import your custom MedicineSlot widget
import 'package:tambal/models/medicine.dart'; // Import your Medicine model

class MedicineSlotSection extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  MedicineSlotSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Medicine Slot',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(
                  Icons.medication_rounded,
                  color: Colors.grey,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: StreamBuilder<List<Medicine>>(
            stream: firestoreService.getMedicines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading medicines'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No medicines available'));
              }

              // Sort the medicines by slot number
              List<Medicine> sortedMedicines = List.from(snapshot.data!)
                ..sort((a, b) => a.slot.compareTo(b.slot));

              // Displaying medicines dynamically in sorted order
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedMedicines.map((medicine) {
                  return MedicineSlot(
                    slotNumber: medicine.slot,
                    medicineName: medicine.name,
                    medicineType: medicine.purpose,
                    stock: medicine.stock,
                    isSelected: false, // Adjust selection logic as needed
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
