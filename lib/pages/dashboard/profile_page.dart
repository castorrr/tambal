import 'package:flutter/material.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Show Reset Confirmation Dialog
  Future<bool?> showResetDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset'),
          content: const Text('Are you sure you want to reset your data? '),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              child: const Text('Reset'),
            )
          ],
        );
      },
    );
  }

  // Show Logout Confirmation Dialog
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            )
          ],
        );
      },
    );
  }

  // Show a loading dialog
  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      barrierDismissible: false, // Prevents user from closing it
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    String getInitials(String name) {
      List<String> nameParts = name.split(" ");
      String initials = "";
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0];
        if (nameParts.length > 1) {
          initials += nameParts[1][0];
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
            const SizedBox(height: 40),
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
                        : null,
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
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // User Email
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  // Username
                  Text(
                    user != null ? '@${user.username}' : '',
                    style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 30),
                  // Row with Reset & Logout Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      ElevatedButton(
                        onPressed: () async {
                          // Store the current context safely
                          if (!context.mounted) return;
                          final BuildContext currentContext = context;

                          // Store navigator and scaffold references BEFORE async calls
                          final navigator = Navigator.of(currentContext);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(currentContext);

                          final bool? shouldReset =
                              await showResetDialog(currentContext);

                          // Ensure the widget is still mounted after the async operation
                          if (!currentContext.mounted) return;

                          if (shouldReset == true) {
                            final firestoreService = FirestoreService();
                            final realTimeService = RealtimeDatabaseService();

                            // Show loading dialog using the stored context
                            showLoadingDialog(
                                currentContext, "Resetting data...");

                            // Perform async operations
                            await firestoreService.resetFirestoreCollections();
                            await realTimeService
                                .resetRealtimeDatabaseSchedules();

                            // Ensure the widget is still mounted before modifying UI
                            if (!currentContext.mounted) return;

                            // Close loading dialog
                            navigator.pop();

                            // Show success message
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Profile data reset successfully!'),
                                backgroundColor: Colors.blueAccent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text('Reset',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      const SizedBox(width: 20),
                      // Logout Button
                      ElevatedButton(
                        onPressed: () async {
                          // Store context-dependent values BEFORE any async calls
                          final navigator = Navigator.of(context);
                          ScaffoldMessenger.of(context);
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);

                          final bool? shouldLogout =
                              await showLogoutDialog(context);

                          if (shouldLogout == true) {
                            await authProvider.signOut();

                            // Ensure context is still mounted before navigation
                            if (navigator.mounted) {
                              navigator.pushReplacementNamed('/login');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Logout',
                            style: TextStyle(fontSize: 18, color: Colors.red)),
                      ),
                    ],
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
