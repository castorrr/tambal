import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CustomPatientListCard extends StatefulWidget {
  final String name;
  final String gender;
  final int age;
  final int slot;
  final String readyForDispense; // 🔹 New field
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CustomPatientListCard({
    super.key,
    required this.name,
    required this.gender,
    required this.age,
    required this.slot,
    required this.readyForDispense, // 🔹 Accepts data for next dispense
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
    return gender.toLowerCase() == 'male' ? 'M' : 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      child: Slidable(
        key: ValueKey(widget.name),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => widget.onEdit(),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (context) => widget.onDelete(),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isTapped ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Avatar and Slot Number
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade50,
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Transform.translate(
                        offset:
                            const Offset(0, -2), // Adjust Y-axis positioning
                        child: ClipOval(
                          child: Image.asset(
                            getGenderImage(widget.gender),
                            width: 80, // Increase for better fit
                            height: 80,
                            fit: BoxFit
                                .cover, // Ensures full coverage inside the circle
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No. ${widget.slot}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 14),
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.medication,
                            color: Colors.green,
                            size: 18,
                          ),
                          Text(
                            'Ready for Dispense: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            widget.readyForDispense,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
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
        ),
      ),
    );
  }
}
