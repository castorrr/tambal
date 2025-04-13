import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date and time
import 'package:tambal/pages/dashboard/tabs/patients_page.dart';
import 'package:tambal/pages/dashboard/tabs/monitor_page.dart'; // Import Monitor Page
import 'package:tambal/widgets/custom_app_bar.dart'; // Importing custom AppBar
import 'package:tambal/widgets/custom_dashboard_alerts.dart';
import 'package:tambal/widgets/custom_dashboard_analytics.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  MainDashboardState createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      DashboardPage(onTabChange: onTabTapped), // Pass tab change function
      const PatientsPage(),
      const MonitorPage(),
    ]);
  }

  // Method to handle tab selection
  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // Logout Dialog: To log out the user and redirect to the login screen
  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you really want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Stay logged in
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Log out
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          showLogoutDialog: _showLogoutDialog), // Use the custom AppBar
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: currentIndex,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor),
            label: 'Monitor',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardPage({super.key, required this.onTabChange});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  String formattedTime = '';
  String formattedDate = '';
  String mealTime = '';
  Timer? _timer; // Store Timer reference

  @override
  void initState() {
    super.initState();
    _updateDateTime(); // Initialize date and time

    // Create periodic timer and store reference
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _updateDateTime();
      } else {
        timer.cancel(); // Cancel timer if widget is disposed
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent setState() on disposed widget
    super.dispose();
  }

  void _updateDateTime() {
    if (!mounted) return; // Prevent updates if widget is disposed
    DateTime now = DateTime.now();
    setState(() {
      formattedTime = DateFormat('hh:mm a').format(now); // Format time
      formattedDate = DateFormat('EEEE, MMMM d, y').format(now); // Format date
      mealTime = _getMealTime(now.hour); // Get meal greeting
    });
  }

  String _getMealTime(int hour) {
    const mealTimes = {
      'Breakfast': [5, 6, 7, 8],
      'Lunch': [10, 11, 12, 13],
      'Dinner': [16, 17, 18, 19],
    };

    for (var entry in mealTimes.entries) {
      String meal = entry.key;
      List<int> times = entry.value;

      if (hour == times[0]) return 'Almost time for $meal';
      if (hour >= times[1] && hour < times[2]) return 'Time for $meal';
      if (hour == times[2]) return '$meal is almost over';
      if (hour == times[3]) return '$meal has ended';
    }

    return '-----'; // Hide message outside meal times
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),

            // Centered Welcome Message
            const Text(
              'Welcome to TAMBAL-PD',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Centered Date & Time
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            // Meal Time Prompt inside a Card
            if (mealTime.isNotEmpty)
              // Meal Time Prompt inside a Card
              Card(
                elevation: 2, // Light shadow for a slight depth effect
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Soft rounded edges
                  side: BorderSide(
                      color: mealTime == '-----'
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.green.withOpacity(0.8),
                      width: 1), // Subtle border
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: mealTime == '-----'
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.greenAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color:
                              mealTime == '-----' ? Colors.grey : Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mealTime, // Displays meal time or "-----"
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: mealTime == '-----'
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Dashboard Analytics & Alerts
            CustomDashboardAnalytics(onTabChange: widget.onTabChange),
            const AlertListWidget(),
          ],
        ),
      ),
    );
  }
}
