import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              'Welcome to TAMBAL-PD!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),  // Add some space between the text and the image
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
                  textStyle: const TextStyle(fontSize: 16),
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
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
