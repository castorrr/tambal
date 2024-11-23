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
          child: SingleChildScrollView(
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
                    errorText: authProvider.errorMessage ==
                            'No user found for this email'
                        ? authProvider.errorMessage
                        : null,
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
                    errorText: authProvider.errorMessage == 'Incorrect password'
                        ? authProvider.errorMessage
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (authProvider.errorMessage != null &&
                    authProvider.errorMessage !=
                        'No user found for this email' &&
                    authProvider.errorMessage != 'Incorrect password')
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
                          try {
                            // Call the signIn method in AuthProvider
                            await authProvider.signIn(
                              _usernameController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            // Navigate to dashboard if login is successful
                            if (authProvider.user != null && context.mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/main-dashboard');
                            }
                          } catch (e) {
                            // Error messages are already handled in the provider
                            setState(() {});
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
                const SizedBox(height: 20),
                // OR Divider
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Divider(thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "or sign in with",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Divider(thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Sign in with Google Button
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          try {
                            await authProvider.signInWithGoogle();

                            if (authProvider.user != null && context.mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/main-dashboard');
                            }
                          } catch (e) {
                            setState(() {});
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    side: const BorderSide(color: Colors.grey),
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
      ),
    );
  }
}
