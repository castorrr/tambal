import 'package:flutter/material.dart';

class MedicineSlot extends StatelessWidget {
  final int slotNumber;
  final String medicineName;
  final String medicineType;
  final int stock;
  final bool isSelected;

  const MedicineSlot({
    super.key,
    required this.slotNumber,
    required this.medicineName,
    required this.medicineType,
    required this.stock,
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
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
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
            width: 1,
            height: 40,
            color: isSelected ? Colors.white : Colors.grey,
          ),

          const SizedBox(width: 16), // Spacing between line and text

          // Medicine name and type (center)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  medicineName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
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

          // Vertical Divider (line before the stock icon and number)
          Container(
            width: 1,
            height: 40,
            color: isSelected ? Colors.white : Colors.grey,
          ),

          const SizedBox(
              width: 24), // Spacing between line and stock icon/number

          // Stock icon and number (right side, vertically aligned)
          Column(
            children: [
              Icon(Icons.inventory, // Inventory icon
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 18),
              const SizedBox(height: 4),
              Text(
                stock.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
