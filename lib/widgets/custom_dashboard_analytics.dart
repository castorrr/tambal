import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CustomDashboardAnalytics extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  final Function(int) onTabChange; // Callback function for tab switching

  CustomDashboardAnalytics({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStreamStatCard(
                title: "Patients",
                stream: firestoreService.getTotalPatients(),
                icon: Icons.group_rounded,
                color: Colors.blue,
                isLargeText: true,
                onTap: () => onTabChange(1), // Switch to Patients Page
              ),
              const SizedBox(width: 16),
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
    bool isLargeText = false,
    required VoidCallback onTap, // OnTap function to switch tabs
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Call onTap function to change tab
        child: StreamBuilder<T>(
          stream: stream,
          builder: (context, snapshot) {
            String value = snapshot.hasData ? snapshot.data.toString() : "--";
            return _buildStatCard(title, value, icon, color, isLargeText);
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingScheduleCard() {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChange(1),
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

            String displayTime = scheduleTime != "--" ? scheduleTime : "";
            return _buildStatCard(
              "Upcoming Schedule",
              "$patientName${displayTime.isNotEmpty ? '\n$displayTime' : ''}",
              Icons.calendar_today_rounded,
              Colors.purple,
              false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isLargeText,
  ) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isLargeText ? 30 : 23,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(1.0),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
