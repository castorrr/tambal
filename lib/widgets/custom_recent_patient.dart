import 'package:flutter/material.dart';

class RecentPatientCard extends StatelessWidget {
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String medicineDispensed;

  const RecentPatientCard({
    super.key,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.medicineDispensed,
  });

  // Helper function to extract initials from the patient's name
  String getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0]; // Take the first letter of each name part
      }
    }
    return initials.toUpperCase(); // Return the initials in uppercase
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners for the card
      ),
      elevation: 4, // Shadow for the card
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Margin around the card
      color: Colors.white, // Background color matching the design
      child: Padding(
        padding: const EdgeInsets.all(16), // Padding inside the card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circle Avatar with Initials
            CircleAvatar(
              radius: 30, // Adjust size of the avatar
              backgroundColor: const Color(0xFF3A86FF), // Background color for the avatar
              child: Text(
                getInitials(patientName), // Show initials from the patient's name
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Initials text color
                ),
              ),
            ),
            const SizedBox(width: 16), // Space between the picture and text

            // Column for Patient Info (Name, Gender, Age)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Name
                  Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A86FF), // Same blue as the title
                    ),
                  ),
                  const SizedBox(height: 8), // Space between name and gender/age

                  // Gender and Age Row
                  Row(
                    children: [
                      // Gender
                      Text(
                        'Gender: $patientGender',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16), // Space between gender and age

                      // Age
                      Text(
                        'Age: $patientAge',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Space between gender/age and medicine

                  // Medicine Dispensed
                  Row(
                    children: [
                      const Icon(Icons.medication, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Dispensed: $medicineDispensed',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
