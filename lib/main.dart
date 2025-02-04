import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:tambal/pages/splash_screen.dart';

import 'pages/auth/login.dart';
import 'pages/auth/signup.dart';
import 'pages/auth/forgot_password.dart';
import 'pages/dashboard/main_dashboard.dart';
import 'pages/dashboard/alerts_page.dart';
import 'pages/dashboard/wifi_page.dart';
import 'pages/welcome_page.dart';
import 'pages/dashboard/tabs/medicine_page.dart';
import 'pages/dashboard/tabs/patients_page.dart';
import 'pages/dashboard/profile_page.dart';

import 'providers/auth_provider.dart'; // AuthProvider
import 'services/firestore_service.dart'; // FirestoreService
import 'services/realtime_database_service.dart'; // RealtimeDatabaseService
import 'services/notification_service.dart';

final Logger logger = Logger();
final notificationService = NotificationService();
final realtimeDatabaseService = RealtimeDatabaseService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    logger.e('Firebase initialization error: $e');
  }

  try {
    // Initialize notifications
    notificationService.initialize();
    notificationService.startListeningForScheduleUpdates();
  } catch (e, stackTrace) {
    logger.e('Error initializing Awesome Notifications: $e',
        error: e, stackTrace: stackTrace);
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
          create: (_) {
            final authProvider = AuthProvider();
            authProvider
                .initializeCurrentUser(); // Initialize the user when the app starts
            return authProvider;
          },
        ),
        // Auth state provider
        Provider<FirestoreService>(
            create: (_) => FirestoreService()), // FirestoreService provider
        Provider<RealtimeDatabaseService>(
            create: (_) =>
                RealtimeDatabaseService()), // RealtimeDatabaseService provider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tambal-PD',
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
        home: const SplashScreen(),
        routes: {
          '/welcome': (context) => const WelcomePage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/main-dashboard': (context) => const MainDashboard(),
          '/medicine-page': (context) => const MedicinePage(),
          '/patients-page': (context) => const PatientsPage(),
          '/profile-page': (context) => const ProfilePage(),
          '/alerts-page': (context) => const AlertsPage(),
          '/wifi-page': (context) => const WifiConfigPage(),
        },
      ),
    );
  }
}
