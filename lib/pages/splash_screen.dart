import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'welcome_page.dart';
import 'dashboard/main_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _checkAuthenticationState();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  Future<void> _checkAuthenticationState() async {
    // Ensure splash screen is shown for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isAuthenticated = false;

    try {
      await authProvider.initializeCurrentUser();
      isAuthenticated = authProvider.user != null;
    } catch (e) {
      // Log error or handle it appropriately
      isAuthenticated = false;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              isAuthenticated ? const MainDashboard() : const WelcomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
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
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
