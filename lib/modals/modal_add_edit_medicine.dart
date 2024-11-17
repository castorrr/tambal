import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:tambal/utils/form_validators.dart';

class ModalAddMedicine extends StatefulWidget {
  final List<int> availableSlots;
  final Medicine? medicine; // Optional Medicine object for editing
  final FirestoreService _firestoreService = FirestoreService();

  ModalAddMedicine({
    super.key,
    required this.availableSlots,
    this.medicine,
  });

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
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      // If a Medicine object is provided, pre-fill the fields
      nameController.text = widget.medicine!.name;
      purposeController.text = widget.medicine!.purpose;
      descriptionController.text = widget.medicine!.description;
      stockController.text = widget.medicine!.stock.toString();
      selectedSlot = widget.medicine!.slot.toString();
    } else if (widget.availableSlots.isNotEmpty) {
      // Set default value for the dropdown if adding a new medicine
      selectedSlot = widget.availableSlots.first.toString();
    }

    // Ensure selectedSlot is valid
    if (selectedSlot != null &&
        !widget.availableSlots.contains(int.tryParse(selectedSlot!))) {
      selectedSlot = null; // Reset to null if the selected slot is invalid
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String userId = authProvider.user?.uid ?? '';

    return AlertDialog(
      title: Text(widget.medicine != null ? 'Edit Medicine' : 'Add Medicine'),
      content: SingleChildScrollView(
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
              widget.medicine == null
                  ? (widget.availableSlots.isNotEmpty
                      ? DropdownButtonFormField<String>(
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
                          validator: (value) => FormValidators.requiredField(
                              value, 'Slot Number'),
                        )
                      : const Text('No slot available'))
                  : Text(
                      'Slot Number: ${widget.medicine!.slot}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        if (widget.medicine != null || widget.availableSlots.isNotEmpty)
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                String name = nameController.text;
                String purpose = purposeController.text;
                String description = descriptionController.text;
                int stock = int.tryParse(stockController.text) ?? 0;

                bool success = false;
                try {
                  if (widget.medicine != null) {
                    // Update existing medicine without changing the slot
                    await widget._firestoreService.updateMedicine(
                      id: widget.medicine!.id,
                      name: name,
                      purpose: purpose,
                      description: description,
                      stock: stock,
                      slot: widget.medicine!.slot,
                      // Use the existing slot
                      userId: userId,
                    );
                  } else {
                    // Add new medicine
                    await widget._firestoreService.addMedicine(
                      name: name,
                      purpose: purpose,
                      description: description,
                      stock: stock,
                      slot: int.parse(selectedSlot!),
                      userId: userId,
                    );
                  }
                  success = true;
                } catch (e) {
                  logger.e('Error saving medicine: $e');
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
        const SnackBar(content: Text('Failed to save medicine')),
      );
    }
  }
}

// Function to show the modal
void showModalAddOrEditMedicine(BuildContext context, List<int> availableSlots,
    {Medicine? medicine}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ModalAddMedicine(
        availableSlots: availableSlots,
        medicine: medicine,
      );
    },
  );
}
