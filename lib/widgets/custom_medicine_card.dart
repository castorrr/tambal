// File: custom_medicine_card.dart
import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_medicine_pill.dart'; // Import your custom MedicineSlot widget

class MedicineSlotSection extends StatelessWidget {
  const MedicineSlotSection({super.key});

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
                  Icons.medication_rounded, // Medicine icon
                  color: Colors.grey,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width, // Expands to full screen width
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade100, // Custom background color for the section
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MedicineSlot(
                slotNumber: 1,
                medicineName: 'Biogesic',
                medicineType: 'Fever',
                isSelected: false,
              ),
              MedicineSlot(
                slotNumber: 2,
                medicineName: 'Neozep',
                medicineType: 'Phlegm',
                isSelected: true,
              ),
              MedicineSlot(
                slotNumber: 3,
                medicineName: 'Tiki-Tiki',
                medicineType: 'Growth',
                isSelected: false,
              ),
            ],
          ),
        ),// Added space to avoid overflow
      ],
    );
  }
}
