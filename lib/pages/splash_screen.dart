import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart'; // Import provider
import 'package:tambal/providers/auth_provider.dart'; // Import AuthProvider
import 'welcome_page.dart';
import 'dashboard/main_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _navigateWithFadeOut();
  }

  void _startAnimation() {
    setState(() {
      _visible = true; // Start fade-in
    });
  }

  void _navigateWithFadeOut() {
    // Trigger fade-out after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false; // Start fade-out
        });
      }
    });

    // Navigate based on user authentication state after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {  // Check if the widget is still mounted
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0, // Controls fade-in and fade-out
          duration: const Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'TAMBAL-PD',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 62,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'Ensuring Timely Care, One Dose at a Time',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
