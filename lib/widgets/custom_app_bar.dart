import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:tambal/pages/dashboard/profile_page.dart'; // Importing the ProfilePage
import 'package:tambal/pages/dashboard/alerts_page.dart'; // Importing the AlertsPage
import 'package:tambal/pages/dashboard/wifi_page.dart';
import 'package:tambal/providers/auth_provider.dart'; // Import AuthProvider

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<bool?> Function()
      showLogoutDialog; // Pass in logout dialog method

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

    // Function to get the first two names from the user's full name
    String getFirstTwoNames(String name) {
      List<String> nameParts = name.split(" ");
      if (nameParts.length >= 2) {
        return "${nameParts[0]} ${nameParts[1]}"; // Return the first two names
      } else {
        return name; // If only one name exists, return it as is
      }
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
                    ? NetworkImage(
                        user!.profilePicture!) // Show profile picture
                    : null, // Null if no image
                child: user?.profilePicture == null
                    ? Text(
                        getInitials(user?.name ?? 'User'),
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
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the text vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align text to the left
                  children: [
                    const Text(
                      'Hi, Welcome Back',
                      style: TextStyle(
                        fontSize: 12, // Adjust font size for the smaller text
                        color: Colors.blue, // Set the text color to blue
                      ),
                      overflow: TextOverflow.ellipsis, // Handle overflow
                    ),
                    Flexible(
                      child: Text(
                        getFirstTwoNames(user?.name ?? 'Guest User'),
                        style: const TextStyle(
                          fontSize: 14, // Adjust font size for the name
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Set the user name color
                        ),
                        overflow: TextOverflow.ellipsis, // Handle overflow
                        maxLines: 1, // Restrict to a single line
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
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () {
              // Navigate to AlertsPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WifiConfigPage()),
              );
            },
          ),
        ),
        // Notification bell icon
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to AlertsPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
