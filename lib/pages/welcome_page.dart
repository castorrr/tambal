import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  WelcomePageState createState() =>WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _startFadeIn();
  }

  void _startFadeIn() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _visible = true;  // Trigger the fade-in
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(seconds: 2),  // Duration of the fade-in effect
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
              Text(
                'TAMBAL-PD',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 60, fontWeight: FontWeight.w600),
              ),
              Image.asset(
                'assets/images/logo2.png',  // Replace with your PNG image
                height: 400.0,
                width: 400.0,
              ),
              const SizedBox(height: 20),  // Add some space between the image and the buttons
              SizedBox(
                width: 200,  // Set a fixed width for both buttons
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,  // Set the same fixed width for the second button
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
