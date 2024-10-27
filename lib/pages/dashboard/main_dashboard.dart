import 'package:flutter/material.dart';// Importing the custom MedicineSlot widget
import 'package:tambal/pages/dashboard/tabs/medicine_page.dart'; // Importing the MedicinePage
import 'package:tambal/pages/dashboard/tabs/patients_page.dart'; // Importing the PatientsPage
import 'package:tambal/widgets/custom_medicine_card.dart'; // Importing the MedicineSlot UI file

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  MainDashboardState createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const MedicinePage(),
    const PatientsPage(),
  ];

  final List<String> _titles = [
    'Home',       // Title for the Home tab
    'Medicine',   // Title for the Medicine tab
    'Patients',   // Title for the Patients tab
  ];

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showExitDialog() ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[currentIndex]), // Dynamically set the AppBar title
          backgroundColor: Theme.of(context).primaryColor,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: const Text('John Doe'),
                accountEmail: const Text('johndoe@example.com'),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'JD',
                    style: TextStyle(fontSize: 24.0, color: Colors.blue),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pushNamed(context, '/welcome');
                },
              ),
            ],
          ),
        ),
        body: _pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: currentIndex,
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
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Now using the MedicineSlotSection
          MedicineSlotSection(),
        ],
      ),
    );
  }
}
