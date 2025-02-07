import 'package:flutter/material.dart';

class ModalSelectMedicine extends StatefulWidget {
  final List<Map<String, String>> availableMedicines;
  final Function(List<Map<String, dynamic>>) onMedicinesSelected;

  const ModalSelectMedicine({
    super.key,
    required this.availableMedicines,
    required this.onMedicinesSelected,
  });

  @override
  ModalSelectMedicineState createState() => ModalSelectMedicineState();
}

class ModalSelectMedicineState extends State<ModalSelectMedicine> {
  final List<Map<String, dynamic>> tempSelectedMedicines = [];

  @override
  Widget build(BuildContext context) {
    // Sort medicines by slot before displaying
    List<Map<String, String>> sortedMedicines = List.from(
        widget.availableMedicines)
      ..sort((a, b) => int.parse(a['slot']!).compareTo(int.parse(b['slot']!)));

    return AlertDialog(
      title: const Text('Select Medicines, Slots, and Quantity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedMedicines.map((medicine) {
            final slot = medicine['slot']!;
            final name = medicine['name']!;

            // Find if the medicine is already selected
            var selectedMedicine = tempSelectedMedicines.firstWhere(
              (m) => m['name'] == name && m['slot'] == slot,
              orElse: () => <String, dynamic>{},
            );

            bool isSelected = selectedMedicine.isNotEmpty;
            int quantity = isSelected ? selectedMedicine['quantity'] : 1;

            return Column(
              children: [
                CheckboxListTile(
                  title: Text('Slot $slot: $name'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        tempSelectedMedicines.add({
                          'slot': slot,
                          'name': name,
                          'quantity': quantity,
                        });
                      } else {
                        tempSelectedMedicines.removeWhere(
                          (m) => m['name'] == name && m['slot'] == slot,
                        );
                      }
                    });
                  },
                ),
                if (isSelected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text('Quantity:'),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (quantity > 1) {
                              selectedMedicine['quantity']--;
                            }
                          });
                        },
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            selectedMedicine['quantity']++;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onMedicinesSelected(tempSelectedMedicines);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
