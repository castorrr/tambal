import 'package:flutter/material.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:provider/provider.dart'; // Import Provider

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<bool?> showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Set the text color to red
              ),
              child: const Text('Logout'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the user data from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    String getInitials(String name) {
      List<String> nameParts = name.split(" ");
      String initials = "";
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0]; // First letter of the first name
        if (nameParts.length > 1) {
          initials += nameParts[1][0]; // First letter of the last name
        }
      }
      return initials.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 40), // Add space at the top
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue,
                    backgroundImage: user?.profilePicture != null
                        ? NetworkImage(user!.profilePicture!)
                        : null, // Null if no image
                    child: user?.profilePicture == null
                        ? Text(
                            getInitials(user?.name ?? 'User'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  // User Name
                  Text(
                    user?.name ?? 'Guest User', // Use dynamic user name
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // User Email
                  Text(
                    user?.email ?? '', // Use dynamic user email
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Username
                  Text(
                    user != null ? '@${user.username}' : '', // Display username
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Logout Button
                  ElevatedButton(
                    onPressed: () async {
                      final bool? shouldLogout =
                          await showLogoutDialog(context);
                      if (shouldLogout == true && context.mounted) {
                        // Call signOut to clear session
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.signOut();

                        // Redirect to login page
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
