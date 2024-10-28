import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
// Import your UserModel
import 'package:tambal/pages/dashboard/profile_page.dart'; // Importing the ProfilePage
import 'package:tambal/providers/auth_provider.dart'; // Import AuthProvider

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<bool?> Function() showLogoutDialog; // Pass in logout dialog method

  const CustomAppBar({
    super.key,
    required this.showLogoutDialog,
  });

  @override
  Widget build(BuildContext context) {
    // Access the user data from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Extract initials from the user's name if photoURL is null
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

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leadingWidth: 200, // Adjust the width to prevent overflow
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          child: Row(
            children: [
              // CircleAvatar for the profile picture or initials
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 24, // Adjust size of the avatar
                backgroundImage: user?.profilePicture != null
                    ? NetworkImage(user!.profilePicture!) // Show profile picture
                    : null, // Null if no image
                child: user?.profilePicture == null
                    ? Text(
                  getInitials(user?.name ?? 'User'), // Show initials if no profile picture
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8), // Space between avatar and text
              // Flexible Column for Welcome text and Username to avoid overflow
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the text vertically
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                  children: [
                    const Text(
                      'Hi, WelcomeBack',
                      style: TextStyle(
                        fontSize: 12, // Adjust font size for the smaller welcome text
                        color: Colors.blue, // Set the welcome text color to blue
                      ),
                      overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                    ),
                Flexible(
                  child: Text(
                    user?.name ?? 'Guest User', // Display the user's name
                    style: const TextStyle(
                      fontSize: 14, // Adjust font size for the name
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Set the user name color
                    ),
                    overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                    maxLines: 1, // Restrict the text to a single line (if needed)
                  ),
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Notification bell icon with PopupMenu for notification list
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.notifications), // Notification bell icon
            onSelected: (String result) {
              // Handle notification click
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'notif1',
                child: ListTile(
                  leading: Icon(Icons.notification_important),
                  title: Text('New medicine reminder'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'notif2',
                child: ListTile(
                  leading: Icon(Icons.notification_important),
                  title: Text('Upcoming appointment'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'notif3',
                child: ListTile(
                  leading: Icon(Icons.notification_important),
                  title: Text('Your prescription is ready'),
                ),
              ),
            ],
          ),
        ),
        // Settings Icon with PopupMenu
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.settings), // Settings icon in the app bar
            onSelected: (String result) async {
              if (result == 'Logout') {
                final bool? shouldLogout = await showLogoutDialog();
                if (shouldLogout == true && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
