// lib/patients_page.dart
import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Patients Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
