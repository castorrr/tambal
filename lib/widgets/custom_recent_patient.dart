import 'package:flutter/material.dart';

class RecentPatientCard extends StatelessWidget {
  final String patientName;
  final String day;
  final String time;
  final List<String> medicineList;

  const RecentPatientCard({
    super.key,
    required this.patientName,
    required this.day,
    required this.time,
    required this.medicineList,
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
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Margin around the card
      color: Colors.white, // Background color matching the design
      child: Padding(
        padding: const EdgeInsets.all(16), // Padding inside the card
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adjusted Circle Avatar with Initials
            Padding(
              padding: const EdgeInsets.only(top: 10.0), // Move avatar down
              child: CircleAvatar(
                radius: 40, // Size of the avatar
                backgroundColor:
                    const Color(0xFF3A86FF), // Background color for the avatar
                child: Text(
                  getInitials(
                      patientName), // Show initials from the patient's name
                  style: const TextStyle(
                    fontSize: 24, // Larger font size for initials
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Initials text color
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16), // Space between the avatar and text

            // Expanded Column for Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Name
                  Text(
                    patientName,
                    style: const TextStyle(
                      fontSize: 24, // Increased font size for name
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A86FF), // Same blue as the title
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Handle long names
                  ),
                  const SizedBox(height: 8), // Space between name and day/time

                  // Day and Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date: $day',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Handle overflow
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Time: $time',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Handle overflow
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 8), // Space between day/time and medicine

                  // Medicines in single line
                  Text(
                    'Medicine: ${medicineList.join(', ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Handle overflow
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
