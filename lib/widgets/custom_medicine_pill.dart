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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Shadow color
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Row(
        children: [
          // Slot number (left side)
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

          const SizedBox(width: 12), // Spacing between avatar and line

          // Vertical Divider (line after the slot number)
          Container(
            width: 1, // Thin vertical line
            height: 40, // Adjust height of the line to match content
            color: isSelected ? Colors.white : Colors.grey, // Line color
          ),

          const SizedBox(width: 12), // Spacing between line and text

          // Medicine name and type (center)
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

          const SizedBox(width: 12), // Spacing between text and line

          // Vertical Divider (line before the medicine type)
          Container(
            width: 1, // Thin vertical line
            height: 40, // Adjust height of the line to match content
            color: isSelected ? Colors.white : Colors.grey, // Line color
          ),

          const SizedBox(width: 12), // Spacing between line and icon

          // Placeholder for other icons or text (right side)
          Icon(
            Icons.medication_liquid_rounded,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ],
      ),
    );
  }
}
