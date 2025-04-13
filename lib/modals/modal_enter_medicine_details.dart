import 'package:flutter/material.dart';

class ModalEnterMedicineDetails extends StatefulWidget {
  const ModalEnterMedicineDetails({super.key});

  @override
  State<ModalEnterMedicineDetails> createState() =>
      _ModalEnterMedicineDetailsState();
}

class _ModalEnterMedicineDetailsState extends State<ModalEnterMedicineDetails> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Medicine Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                  labelText: 'Dosage (Optional, e.g., 500mg)'),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Quantity (Optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'name': nameController.text,
                'dosage': dosageController.text.isNotEmpty
                    ? dosageController.text
                    : 'N/A', // Default if empty
                'quantity': quantityController.text.isNotEmpty
                    ? int.tryParse(quantityController.text) ?? 1
                    : 1, // Default to 1 if empty
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
