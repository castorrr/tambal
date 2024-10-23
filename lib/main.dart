import 'package:flutter/material.dart';
import 'package:tambal/pages/forgot_password.dart';
import 'pages/splash_screen.dart';
import 'pages/welcome_page.dart';
import 'pages/login.dart';
import 'pages/signup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: const Color(0xFF3A86FF),
        scaffoldBackgroundColor: const Color(0xFFEDF2FB),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF2B50AA),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Open Sans',
            color: Color(0xFF2B50AA),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF2B50AA),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3A86FF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
