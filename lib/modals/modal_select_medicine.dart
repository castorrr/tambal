import 'package:flutter/material.dart';
import 'package:tambal/modals/modal_enter_medicine_details.dart';

class ModalSelectMedicine extends StatefulWidget {
  final Function(String) onMedicinesSelected; // ✅ Now expects a String

  const ModalSelectMedicine({
    super.key,
    required this.onMedicinesSelected,
  });

  @override
  ModalSelectMedicineState createState() => ModalSelectMedicineState();
}

class ModalSelectMedicineState extends State<ModalSelectMedicine> {
  final List<Map<String, dynamic>> tempSelectedMedicines = [];

  void _addCustomMedicine() async {
    final Map<String, dynamic>? newMedicine =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return const ModalEnterMedicineDetails();
      },
    );

    if (newMedicine != null) {
      setState(() {
        tempSelectedMedicines.add(newMedicine);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Add Medicines',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
        height: 250, // Fixed modal height to avoid large expansion
        child: Column(
          children: [
            Expanded(
              child: tempSelectedMedicines.isEmpty
                  ? const Center(
                      child: Text(
                        'No medicines added yet.\nTap + to add medicines.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempSelectedMedicines.length,
                      itemBuilder: (context, index) {
                        final medicine = tempSelectedMedicines[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(
                              '${medicine['name']} - ${medicine['dosage'] ?? 'N/A'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('Quantity: ${medicine['quantity']}x'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  tempSelectedMedicines.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            // Floating + button for adding medicines
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                mini: true,
                onPressed: _addCustomMedicine,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: tempSelectedMedicines.isNotEmpty
                  ? () {
                      // ✅ Convert medicines list to a single formatted string
                      String formattedMedicines = tempSelectedMedicines
                          .map((m) =>
                              "${m['name']} ${m['dosage'] ?? 'N/A'} ${m['quantity']}x")
                          .join(", "); // Comma-separated

                      widget.onMedicinesSelected(
                          formattedMedicines); // ✅ Pass as String
                      Navigator.of(context).pop();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save Medicines',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
