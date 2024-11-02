import 'package:flutter/material.dart';

class CustomPatientListCard extends StatelessWidget {
  final String name;
  final String gender;
  final int age;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomPatientListCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.onEdit,
    required this.onDelete,
  });

  // Function to get initials from the name
  String getInitials(String name) {
    List<String> nameParts = name.split(" ");
    String initials = "";
    if (nameParts.isNotEmpty) {
      initials = nameParts[0][0]; // First letter of first name
      if (nameParts.length > 1) {
        initials += nameParts[1][0]; // First letter of last name
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // White background for the card
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name of the patient
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Blue color for the name
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              // Gender and Age Row
              Row(
                children: [
                  Text(
                    'Gender: $gender',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Age: $age',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Edit and Delete Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit, // Edit action callback
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete, // Delete action callback
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
