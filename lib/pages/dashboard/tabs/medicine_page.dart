// lib/medicine_page.dart
import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_medicine_card.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column( // Wrap widgets inside a Column for multiple children
        children: <Widget>[
          MedicineSlotSection(),
        ],
      ),
    );
  }
}
