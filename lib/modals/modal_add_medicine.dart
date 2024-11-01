// File: modals/modal_add_medicine.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:tambal/utils/form_validators.dart';

class ModalAddMedicine extends StatefulWidget {
  final List<int> availableSlots; // Keep the availableSlots as passed
  final FirestoreService _firestoreService = FirestoreService();

  ModalAddMedicine({super.key, required this.availableSlots});

  @override
  ModalAddMedicineState createState() => ModalAddMedicineState();
}

class ModalAddMedicineState extends State<ModalAddMedicine> {
  final Logger logger = Logger();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String userId = authProvider.user?.uid ?? '';

    // Set default value for the dropdown if availableSlots is not empty
    if (selectedSlot == null && widget.availableSlots.isNotEmpty) {
      selectedSlot = widget.availableSlots.first.toString();
    }

    return AlertDialog(
      title: const Text('Add Medicine'),
      content: widget.availableSlots.isEmpty
          ? const Text('No slot available')
          : SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                      ),
                      validator: (value) =>
                          FormValidators.requiredField(value, 'Medicine Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of the Medication',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormValidators.positiveInteger,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      decoration: const InputDecoration(
                        labelText: 'Slot Number',
                      ),
                      items: widget.availableSlots.map((int value) {
                        return DropdownMenuItem<String>(
                          value: value.toString(),
                          child: Text('Slot $value'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSlot = newValue;
                        });
                      },
                      validator: (value) =>
                          FormValidators.requiredField(value, 'Slot Number'),
                    ),
                  ],
                ),
              ),
            ),
      actions: widget.availableSlots.isEmpty
          ? <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ]
          : <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String name = nameController.text;
                    String purpose = purposeController.text;
                    String description = descriptionController.text;
                    int stock = int.tryParse(stockController.text) ?? 0;

                    bool success = false;
                    try {
                      // Perform the async operation
                      await widget._firestoreService.addMedicine(
                        name: name,
                        purpose: purpose,
                        description: description,
                        stock: stock,
                        slot: int.parse(selectedSlot!),
                        userId: userId,
                      );
                      success = true;
                    } catch (e) {
                      logger.e('Error adding medicine: $e');
                    }

                    _handlePostSave(success);
                  }
                },
                child: const Text('Save'),
              ),
            ],
    );
  }

  void _handlePostSave(bool success) {
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add medicine')),
      );
    }
  }
}

// Function to show the modal
void showModalAddMedicine(BuildContext context, List<int> availableSlots) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ModalAddMedicine(availableSlots: availableSlots);
    },
  );
}
