// File: main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'package:tambal/pages/auth/forgot_password.dart';
import 'package:tambal/pages/dashboard/main_dashboard.dart';
import 'package:tambal/pages/splash_screen.dart';
import 'package:tambal/pages/welcome_page.dart';
import 'package:tambal/pages/auth/login.dart';
import 'package:tambal/pages/auth/signup.dart';
import 'package:tambal/pages/dashboard/tabs/medicine_page.dart';
import 'package:tambal/pages/dashboard/tabs/patients_page.dart';
import 'package:tambal/pages/dashboard/profile_page.dart';

import 'package:tambal/providers/auth_provider.dart'; // AuthProvider
import 'package:tambal/services/firestore_service.dart'; // FirestoreService

final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    logger.e('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider()), // Auth state provider
        Provider<FirestoreService>(
            create: (_) => FirestoreService()), // FirestoreService provider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
          '/main-dashboard': (context) => const MainDashboard(),
          '/medicine-page': (context) => const MedicinePage(),
          '/patients-page': (context) => const PatientsPage(),
          '/profile-page': (context) => const ProfilePage(),
        },
      ),
    );
  }
}
