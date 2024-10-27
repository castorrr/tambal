import 'package:flutter/material.dart';
import 'package:tambal/pages/auth/forgot_password.dart';
import 'package:tambal/pages/dashboard/main_dashboard.dart';
import 'package:tambal/pages/splash_screen.dart';
import 'package:tambal/pages/welcome_page.dart';
import 'package:tambal/pages/auth/login.dart';
import 'package:tambal/pages/auth/signup.dart';
import 'package:tambal/pages/dashboard/tabs/medicine_page.dart';
import 'package:tambal/pages/dashboard/tabs/patients_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:tambal/providers/auth_provider.dart'; // Import the AuthProvider
import 'package:logger/logger.dart'; // Import the logger

final Logger logger = Logger(); // Instantiate logger

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Use logger instead of print
    logger.e('Firebase initialization error');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // Use MultiProvider to provide AuthProvider globally
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Auth state provider
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
        },
      ),
    );
  }
}
