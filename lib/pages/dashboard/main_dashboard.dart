import 'package:flutter/material.dart';
import 'package:tambal/pages/dashboard/tabs/medicine_page.dart';
import 'package:tambal/pages/dashboard/tabs/patients_page.dart';
import 'package:tambal/pages/dashboard/tabs/monitor_page.dart'; // Import Monitor Page
import 'package:tambal/widgets/custom_app_bar.dart'; // Importing custom AppBar
import 'package:tambal/widgets/custom_recent_patient_list.dart';
import 'package:tambal/widgets/custom_medicine_card.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  MainDashboardState createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;

  // Adding the MonitorPage to the list of pages
  final List<Widget> _pages = [
    const DashboardPage(),
    const MedicinePage(),
    const PatientsPage(),
    const MonitorPage(), // Monitor Page added here
  ];

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // Exit Dialog: To exit the app without logging out
  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Do you really want to exit the app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Stay in the app
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Exit the app
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Logout Dialog: To log out the user and redirect to login screen
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        final bool shouldPop = await _showExitDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
            showLogoutDialog: _showLogoutDialog), // Use the custom AppBar
        body: _pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: currentIndex,
          backgroundColor: Colors.blue,
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
              icon: Icon(Icons.medication_rounded),
              label: 'Medicine',
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
      ),
    );
  }
}

// Define the DashboardPage class outside the MainDashboardState class
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Now using the MedicineSlotSection
            MedicineSlotSection(),
            RecentPatientListWidget(),
          ],
        ),
      ),
    );
  }
}
