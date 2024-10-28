// lib/patients_page.dart
import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_patient_list_card.dart'; // Import the CustomPatientListCard widget

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample patient data
    final List<Map<String, dynamic>> patients = [
      {
        'name': 'Castor Troy U. Ricafort',
        'gender': 'Female',
        'age': 49,
        'imageUrl': null, // Replace with actual URL
      },
      {
        'name': 'Mr. James Retubado',
        'gender': 'Male',
        'age': 52,
        'imageUrl': null, // Replace with actual URL
      },
      {
        'name': 'Mr. Ronerr Villacarlos',
        'gender': 'Male',
        'age': 61,
        'imageUrl': null, // No image URL, initials will be displayed
      },
    ];
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with "Patients" text and an icon
            Row(
              children: [
                const Icon(Icons.people,
                    size: 28, color: Colors.blue), // Patients icon
                const SizedBox(width: 8), // Space between icon and text
                Text(
                  'Patients',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Space between title and patient list

            // Expanded widget to allow ListView to take up remaining space
            Expanded(
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return CustomPatientListCard(
                    name: patient['name'],
                    gender: patient['gender'],
                    age: patient['age'],
                    imageUrl: patient['imageUrl'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showBottomSheet(context); // Trigger the bottom sheet on FAB press
        },
        backgroundColor: Colors.blue,
        tooltip: 'Add or Edit Patient',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method to show the bottom sheet with options
  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Patient'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Patient selected!')),
                  );
                  // Navigate to Add Patient form/page here
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Patient'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Patient selected!')),
                  );
                  // Navigate to Edit Patient form/page here
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
