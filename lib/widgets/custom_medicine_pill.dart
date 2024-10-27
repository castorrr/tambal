// lib/custom_medicine_pill.dart
import 'package:flutter/material.dart';

class MedicineSlot extends StatelessWidget {
  final int slotNumber;
  final String medicineName;
  final String medicineType;
  final bool isSelected;

  const MedicineSlot({
    super.key,
    required this.slotNumber,
    required this.medicineName,
    required this.medicineType,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3A86FF) : const Color(0xFFE7F1FD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Slot number
          CircleAvatar(
            radius: 20,
            backgroundColor: isSelected ? Colors.white : Colors.white70,
            child: Text(
              slotNumber.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF3A86FF) : Colors.black,
              ),
            ),
          ),
          // Medicine name and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  medicineName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medicineType,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Placeholder for other icons or text (optional)
          Icon(
            Icons.medication_liquid_rounded,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ],
      ),
    );
  }
}
