import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
  bool isTapped = false;

  // Function to get gender-based image
  String getGenderImage(String gender) {
    return gender.toLowerCase() == 'male'
        ? 'assets/images/Male.png'
        : 'assets/images/Female.png';
  }

  // Function to convert gender to abbreviation
  String getGenderAbbreviation(String gender) {
    return gender.toLowerCase() == 'male'
        ? 'M'
        : gender.toLowerCase() == 'female'
            ? 'F'
            : gender;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Slidable(
        key: ValueKey(widget.name),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            // 🟦 Edit Button
            SlidableAction(
              onPressed: (context) => widget.onEdit(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit', // Adds space between icon and text
              padding: EdgeInsets.zero, // Removes extra padding
              autoClose: true, // Closes the slide after clicking
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            // 🔴 Delete Button (Fixed width to show full "Delete" text)
            SlidableAction(
              onPressed: (context) => widget.onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              padding: EdgeInsets.zero, // ✅ Removes extra padding
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            )
          ],
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => isTapped = true),
          onTapUp: (_) {
            setState(() => isTapped = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => isTapped = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: isTapped ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 67,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -3,
                        left: 0,
                        right: 0,
                        child: ClipOval(
                          child: Image.asset(
                            getGenderImage(widget.gender),
                            width: 70,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
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
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Age: ${widget.age}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
