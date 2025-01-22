import 'package:flutter/material.dart';

class CustomPatientListCard extends StatefulWidget {
  final String name;
  final String gender;
  final int age;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CustomPatientListCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<CustomPatientListCard> createState() => _CustomPatientListCardState();
}

class _CustomPatientListCardState extends State<CustomPatientListCard> {
  bool isTapped = false; // Tracks whether the card is tapped

  // Function to get initials from the name
  String getInitials(String name) {
    List<String> nameParts = name.trim().split(" ");
    String initials = "";
    if (nameParts.isNotEmpty) {
      initials = nameParts[0][0];
      if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
        initials += nameParts[1][0];
      }
    }
    return initials.toUpperCase();
  }

  // Function to convert gender to its abbreviation
  String getGenderAbbreviation(String gender) {
    if (gender.toLowerCase() == 'male') {
      return 'M';
    } else if (gender.toLowerCase() == 'female') {
      return 'F';
    }
    return gender; // Return original value if it's neither "male" nor "female"
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Increase padding
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            isTapped = true; // Change the state immediately on tap
          });
        },
        onTapUp: (_) {
          setState(() {
            isTapped = false; // Revert state after tap
          });
          widget.onTap(); // Trigger the onTap callback
        },
        onTapCancel: () {
          setState(() {
            isTapped = false; // Revert state if the tap is canceled
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Faster animation
          decoration: BoxDecoration(
            color: isTapped
                ? Colors.blue.shade50
                : Colors.white, // Change color on tap
            borderRadius:
                BorderRadius.circular(16), // Adjust radius for larger card
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6, // Increased blur for a softer shadow
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0), // Increase padding inside card
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CircleAvatar with initials
                CircleAvatar(
                  radius: 28, // Increase radius for a larger avatar
                  backgroundColor: Colors.blue,
                  child: Text(
                    getInitials(widget.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20, // Increase font size for initials
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                    width: 16), // Increase spacing between avatar and details

                // Name and Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 22, // Increase font size for name
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Gender: ${getGenderAbbreviation(widget.gender)}',
                            style: const TextStyle(
                              fontSize:
                                  14, // Slightly larger text size for details
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Age: ${widget.age}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Column with Edit & Delete Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue,
                              size: 28), // Increase icon size
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red,
                              size: 28), // Increase icon size
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
