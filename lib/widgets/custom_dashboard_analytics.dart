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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Flexible(
                child: _buildStreamStatCard(
                  title: "Patients",
                  stream: firestoreService.getTotalPatients(),
                  icon: Icons.group_rounded,
                  color: Colors.blue,
                  isLargeText: true, // 🔥 Patients text is large
                  onTap: () => onTabChange(1),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _buildUpcomingScheduleCard(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreamStatCard<T>({
    required String title,
    required Stream<T> stream,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLargeText, // 🔥 Add isLargeText here
  }) {
    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<T>(
        stream: stream,
        builder: (context, snapshot) {
          String value = snapshot.hasData ? snapshot.data.toString() : "--";
          return _buildStatCard(
              title, value, icon, color, isLargeText); // Pass isLargeText
        },
      ),
    );
  }

  Widget _buildUpcomingScheduleCard() {
    return GestureDetector(
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
            false, // 🔥 Use smaller text for Upcoming Schedule
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isLargeText, // 🔥 Now added here
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;

        // 🔥 Responsive font sizes based on screen width
        double titleFontSize = screenWidth < 400 ? 10 : 13;
        double valueFontSize = isLargeText
            ? (screenWidth < 400 ? 26 : 40) // Large text for "Patients"
            : (screenWidth < 400
                ? 18
                : 24); // 🔥 Smaller text for "Upcoming Schedule"

        return Container(
          height: 150,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: titleFontSize,
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
                      fontSize:
                          valueFontSize, // 🔥 Smaller text for Upcoming Schedule
                      fontWeight: FontWeight.w800,
                      color: color,
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
      },
    );
  }
}
