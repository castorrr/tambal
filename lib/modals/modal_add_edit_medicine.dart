import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:tambal/utils/form_validators.dart';

class ModalAddMedicine extends StatefulWidget {
  final List<int> availableSlots;
  final Medicine? medicine; // Optional Medicine object for editing
  final FirestoreService _firestoreService = FirestoreService();
  final RealtimeDatabaseService _realtimeDatabaseService =
      RealtimeDatabaseService();

  ModalAddMedicine({super.key, required this.availableSlots, this.medicine});

  @override
  ModalAddMedicineState createState() => ModalAddMedicineState();
}

class ModalAddMedicineState extends State<ModalAddMedicine> {
  final Logger logger = Logger();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? selectedSlot;
  bool isLoading = false; // Track if saving is in progress

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      purposeController.text = widget.medicine!.purpose;
      stockController.text = widget.medicine!.stock.toString();
      selectedSlot = widget.medicine!.slot.toString();
    } else if (widget.availableSlots.isNotEmpty) {
      selectedSlot = widget.availableSlots.first.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) =>
                    FormValidators.requiredField(value, 'Medicine Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                    labelText: 'Purpose of the Medication'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: stockController, // ✅ Now user-editable
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number, // ✅ Restricts to numbers
                validator: (value) =>
                    FormValidators.requiredField(value, 'Stock'),
              ),
              const SizedBox(height: 10),
              widget.medicine == null
                  ? (widget.availableSlots.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          value: selectedSlot,
                          decoration:
                              const InputDecoration(labelText: 'Slot Number'),
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
                  : Text('Slot Number: ${widget.medicine!.slot}',
                      style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!isLoading) Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        if (widget.medicine != null || widget.availableSlots.isNotEmpty)
          ElevatedButton(
            onPressed:
                isLoading ? null : _saveMedicine, // Prevent multiple taps
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Save'),
          ),
      ],
    );
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Saving, please wait...'),
            ],
          ),
        );
      },
    );
  }

  /// Hide loading dialog
  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _saveMedicine() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      _showLoadingDialog(); // Show loading dialog

      String name = nameController.text;
      String purpose = purposeController.text;
      int stock = int.tryParse(stockController.text) ?? 0;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String userId = authProvider.user?.uid ?? '';
      bool success = false;

      try {
        String medicineId;

        if (widget.medicine != null) {
          // Update existing medicine in Firestore
          await widget._firestoreService.updateMedicine(
            id: widget.medicine!.id,
            name: name,
            purpose: purpose,
            stock: stock,
            slot: widget.medicine!.slot,
            userId: userId,
          );

          medicineId = widget.medicine!.id;
        } else {
          // Add new medicine to Firestore
          medicineId = await widget._firestoreService.addMedicine(
            name: name,
            purpose: purpose,
            stock: stock, // Stock is always 0 initially
            slot: int.parse(selectedSlot!),
            userId: userId,
          );
        }

        // ✅ Log: Medicine added/updated, now syncing to RTDB
        logger.i('Syncing medicine $medicineId from Firestore to RTDB...');

        // ✅ Sync to RTDB after Firestore save
        await widget._realtimeDatabaseService
            .syncMedicineFromFirestore(medicineId);

        success = true;
      } catch (e) {
        logger.e('Error saving medicine: $e');
      }

      _hideLoadingDialog();
      _handlePostSave(success);
    }
  }

  void _handlePostSave(bool success) {
    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save medicine')));
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
