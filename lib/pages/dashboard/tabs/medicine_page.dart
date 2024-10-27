// File: medicine_page.dart
import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_medicine_card.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the page with a SingleChildScrollView
      body: const SingleChildScrollView(
        child: Column(
          children: <Widget>[
            MedicineSlotSection(), // Existing MedicineSlotSection
          ],
        ),
      ),

      // Adding a FloatingActionButton at the bottom-right corner
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Handle the action when the button is pressed
          // Navigate to an edit page or open a dialog for editing
        },
        icon: const Icon(Icons.edit), // Edit icon
        label: const Text("Edit"), // Label for the button
        backgroundColor: Theme.of(context).primaryColor, // You can customize the color
      ),
    );
  }
}
