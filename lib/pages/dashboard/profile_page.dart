import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Profile Picture
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue, // Optional: Set a background color
              child: Text(
                'RV', // Replace 'RV' with the initials of the user
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ), // Replace with actual image path
            ),
            const SizedBox(height: 20),
            // User Name
            const Text(
              'Ronerr Villacarlos', // Replace with dynamic user data
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // User Email
            const Text(
              'ronerr.villacarlos@example.com', // Replace with dynamic user data
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                // Handle Edit Profile logic
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Other profile details or options can be added here
            // Example: Displaying more user information
          ],
        ),
      ),
    );
  }
}
