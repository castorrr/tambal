// File: widgets/custom_medicine_card.dart

import 'package:flutter/material.dart';
import 'package:tambal/models/medicine.dart'; // Import the Medicine model

class CustomMedicineCard extends StatelessWidget {
  final Medicine medicine; // Use the Medicine model
  final VoidCallback onDispense; // Callback for the "Dispense" button
  final VoidCallback onEdit; // Callback for the "Edit" button
  final VoidCallback onDelete; // Callback for the "Delete" button

  const CustomMedicineCard({
    super.key,
    required this.medicine,
    required this.onDispense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Medicine Name
                Text(
                  medicine.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8.0),

                // Medicine Purpose
                Text(
                  'Purpose: ${medicine.purpose}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                // Stock Information
                Text(
                  'Stock: ${medicine.stock}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16.0),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // Dispense Button
                    OutlinedButton(
                      onPressed: onDispense,
                      child: const Text('Dispense'),
                    ),

                    // Edit and Delete Buttons
                    Row(
                      children: [
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: onEdit, // Edit action callback
                        ),

                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete, // Delete action callback
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Slot number in the upper right corner
          Positioned(
            top: 8.0,
            right: 8.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Slot ${medicine.slot}', // Display the slot number
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
