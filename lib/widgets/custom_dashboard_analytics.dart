import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CustomDashboardAnalytics extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  CustomDashboardAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStreamStatCard(
                title: "Patients",
                stream: firestoreService.getTotalPatients(),
                icon: Icons.person,
                color: Colors.blue.shade700,
                isLargeText: true, // Large centered text & label
              ),
              const SizedBox(width: 12),
              _buildStreamStatCard(
                title: "Medicine",
                stream: firestoreService.getMedicineTypes(),
                icon: Icons.medical_services,
                color: Colors.green.shade700,
                isLargeText: true, // Large centered text & label
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStreamStatCard(
                title: "Low Stock Medicine",
                stream: firestoreService.getLowestStockMedicine(),
                icon: Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                isLargeText: false, // Smaller centered text & label
              ),
              const SizedBox(width: 12),
              _buildUpcomingScheduleCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamStatCard<T>({
    required String title,
    required Stream<T> stream,
    required IconData icon,
    required Color color,
    bool isLargeText = false, // Flag to determine text size
  }) {
    return Expanded(
      child: StreamBuilder<T>(
        stream: stream,
        builder: (context, snapshot) {
          String value = snapshot.hasData ? snapshot.data.toString() : "--";
          return _buildStatCard(title, value, icon, color, isLargeText);
        },
      ),
    );
  }

  Widget _buildUpcomingScheduleCard() {
    return Expanded(
      child: StreamBuilder<Map<String, String>?>(
          stream: firestoreService.getUpcomingSchedule(),
          builder: (context, snapshot) {
            String patientName = "--";
            String scheduleTime = "--";

            if (snapshot.hasData && snapshot.data != null) {
              var schedule = snapshot.data!;
              patientName = schedule['patientName'] ?? "--";
              scheduleTime = schedule['time'] ?? "--";
            }

            // ✅ If there's a valid schedule, add "@" before the time. Otherwise, leave it empty.
            String displayTime = scheduleTime != "--" ? "@$scheduleTime" : "--";

            return _buildStatCard(
              "Upcoming Schedule",
              "$patientName\n$displayTime", // ✅ Dynamically formatted schedule time
              Icons.schedule,
              Colors.orange.shade700,
              false, // Smaller centered text & label
            );
          }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isLargeText) {
    return Container(
      height: 160, // Keep all boxes uniform in size
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior:
            Clip.none, // Allows the icon to be positioned outside the box
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Value - Large & centered for top 2 cards, smaller for bottom 2
                Expanded(
                  child: Center(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isLargeText ? 40 : 25, // Adjust size
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Label - Centered for all cards
                Text(
                  title,
                  style: TextStyle(
                    fontSize:
                        isLargeText ? 18 : 14, // Smaller font for bottom cards
                    fontWeight: FontWeight.w800,
                    color: Colors.black87.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Icon in the top-right corner
          Positioned(
            top: -14, // Moves the icon slightly above the card
            right: -8, // Moves the icon slightly outside the right edge
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color, // Match the color of the card
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon,
                    size: 30, color: Colors.white), // White icon for visibility
              ),
            ),
          ),
        ],
      ),
    );
  }
}
