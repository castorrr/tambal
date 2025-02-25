// File: main_dashboard.dart
import 'package:flutter/material.dart';
import 'package:tambal/pages/dashboard/tabs/patients_page.dart';
import 'package:tambal/pages/dashboard/tabs/monitor_page.dart'; // Import Monitor Page
import 'package:tambal/widgets/custom_app_bar.dart'; // Importing custom AppBar
import 'package:tambal/widgets/custom_dashboard_alerts.dart';
import 'package:tambal/widgets/custom_dashboard_analytics.dart';
import 'package:tambal/widgets/custom_dashboard_patient.dart';

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
        backgroundColor: Theme.of(context)
            .scaffoldBackgroundColor, // ✅ Fixed background color
        // Set a background color to make the bar visible
        selectedItemColor: Colors.blue,
        // Color for the selected icon
        unselectedItemColor: Colors.grey,
        // Color for unselected icons
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

// Define the DashboardPage class outside the MainDashboardState class
class DashboardPage extends StatelessWidget {
  final Function(int) onTabChange; // Accepts a function to switch tabs

  const DashboardPage({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            CustomDashboardAnalytics(onTabChange: onTabChange),
            CustomDashboardPatient(onTabChange: onTabChange),
            const AlertListWidget(),
          ],
        ),
      ),
    );
  }
}
