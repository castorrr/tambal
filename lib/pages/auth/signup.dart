import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tambal/providers/auth_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Variables to store error messages
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                // Name Text Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _nameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Username Text Field
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: _usernameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Email Text Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError,
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
                    errorText: _passwordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm Password Text Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    errorText: _confirmPasswordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Sign Up Button
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          setState(() {
                            // Reset error messages
                            _nameError = null;
                            _usernameError = null;
                            _emailError = null;
                            _passwordError = null;
                            _confirmPasswordError = null;
                          });

                          // Validate inputs locally
                          if (_nameController.text.isEmpty) {
                            setState(() {
                              _nameError = 'Name cannot be empty';
                            });
                            return;
                          }
                          if (_usernameController.text.isEmpty) {
                            setState(() {
                              _usernameError = 'Username cannot be empty';
                            });
                            return;
                          }
                          if (_emailController.text.isEmpty ||
                              !_emailController.text.contains('@')) {
                            setState(() {
                              _emailError = 'Enter a valid email';
                            });
                            return;
                          }
                          if (_passwordController.text.length < 6) {
                            setState(() {
                              _passwordError =
                                  'Password must be at least 6 characters';
                            });
                            return;
                          }
                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            setState(() {
                              _confirmPasswordError = 'Passwords do not match';
                            });
                            return;
                          }

                          try {
                            await authProvider.signUp(
                              _nameController.text,
                              _usernameController.text,
                              _emailController.text,
                              _passwordController.text,
                            );

                            if (authProvider.user != null && context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          } catch (e) {
                            // Handle specific errors from the provider
                            setState(() {
                              if (e.toString().contains('weak-password')) {
                                _passwordError = 'Password is too weak';
                              } else if (e
                                  .toString()
                                  .contains('email-already-in-use')) {
                                _emailError = 'Email is already in use';
                              } else if (e
                                  .toString()
                                  .contains('invalid-email')) {
                                _emailError = 'Invalid email format';
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                  ),
                                );
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up'),
                ),
                const SizedBox(height: 20),
                // Already have an account? Login here
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Login here',
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
      ),
    );
  }
}
