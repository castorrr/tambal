import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Log In to Your Account',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 40),
              // Email Text Field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              // Password Text Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (authProvider.errorMessage != null)
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              // Login Button
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                  await authProvider.signIn(
                    _usernameController.text,
                    _passwordController.text,
                  );

                  // Use context.mounted to check if the context is still valid
                  if (authProvider.user != null && context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, '/main-dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
              const SizedBox(height: 20),
              // OR Divider
              const Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the content
                children: [
                  SizedBox(
                    width: 60, // Set a fixed width for the divider
                    child: Divider(thickness: 1), // Make the divider thinner
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "or sign in with",
                      style: TextStyle(fontSize: 12), // Reduce the font size to make it more subtle
                    ),
                  ),
                  SizedBox(
                    width: 60, // Set a fixed width for the divider
                    child: Divider(thickness: 1), // Make the divider thinner
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Sign in with Google Button (Icon only)
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                  await authProvider.signInWithGoogle();

                  // Use context.mounted to check if the context is still valid
                  if (authProvider.user != null && context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, '/main-dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  side: const BorderSide(color: Colors.grey), // Add border
                ),
                child: SvgPicture.asset(
                  'assets/images/google_icon.svg',
                  height: 30,
                  width: 30,
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
