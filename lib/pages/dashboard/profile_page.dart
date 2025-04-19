import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showInfo = false;

  // Show Reset Confirmation Dialog
  Future<bool?> showResetDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset'),
        content: const Text('Are you sure you want to reset your data?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text('Reset'),
          )
        ],
      ),
    );
  }

  // Show Logout Confirmation Dialog
  Future<bool?> showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }

  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  String getInitials(String name) {
    final parts = name.split(" ");
    return parts
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : "")
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Picture & Name
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              backgroundImage: user?.profilePicture != null
                  ? NetworkImage(user!.profilePicture!)
                  : null,
              child: user?.profilePicture == null
                  ? Text(
                      getInitials(user?.name ?? 'U'),
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(user?.name ?? 'Guest User',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            // 🔁 AnimatedSwitcher
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              child: _showInfo
                  ? _buildPersonalInfoCard(user)
                  : _buildOptionsCard(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      key: const ValueKey('options'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        children: [
          _buildTile(Icons.info_outline, 'View Information', () {
            setState(() => _showInfo = true);
          }),
          const Divider(),
          _buildTile(Icons.refresh, 'Reset', () async {
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            final shouldReset = await showResetDialog(context);
            if (shouldReset == true) {
              final firestoreService = FirestoreService();
              final realTimeService = RealtimeDatabaseService();
              showLoadingDialog(context, 'Resetting...');
              await firestoreService.resetFirestoreCollections();
              await realTimeService.resetRealtimeDatabaseSchedules();
              navigator.pop(); // close loading dialog
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("Reset successful"),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            }
          }),
          const Divider(),
          _buildTile(Icons.logout, 'Logout', () async {
            final navigator = Navigator.of(context);
            final shouldLogout = await showLogoutDialog(context);
            if (shouldLogout == true) {
              await authProvider.signOut();
              navigator.pushReplacementNamed('/login');
            }
          }),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildPersonalInfoCard(user) {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => setState(() => _showInfo = false),
              ),
              const SizedBox(width: 8),
              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          // Information Fields
          _buildInfoRow("Full Name", user?.name ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow("Email Address", user?.email ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
