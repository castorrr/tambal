import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Login Page',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 40),
              // Username Text Field
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Password Text Field
              TextField(
                obscureText: true, // Hides the password input
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password logic here
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Login Button
              ElevatedButton(
                onPressed: () {
                  // Handle login logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              // Sign in with Google Button
              ElevatedButton.icon(
                onPressed: () {
                  // Handle Google login logic here
                },
                icon: SvgPicture.asset(
                  'assets/images/google_icon.svg',
                  height: 24,
                  width: 24,
                ),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  side: const BorderSide(color: Colors.grey), // Add border
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Sign-up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account? '),
                  GestureDetector(
                    onTap: () {
                      // Handle sign up redirection
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'Sign up here',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
