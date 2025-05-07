import 'package:flutter/material.dart';
import 'package:intimacare_client/home.dart';
import 'package:intimacare_client/services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'verification_page.dart';
import 'prescription_page.dart';
import 'profile.dart';
import 'appointment.dart';

void main() async {
  print("Application starting...");
  WidgetsFlutterBinding.ensureInitialized();
  print("Flutter binding initialized");

  try {
    // Initialize Supabase
    await SupabaseService().initialize();
    print("Supabase initialized successfully");
  } catch (e) {
    print("Error initializing Supabase: $e");
  }

  runApp(const IntimaCareApp());
}

class IntimaCareApp extends StatelessWidget {
  const IntimaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntimaCare',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        fontFamily: 'OpenSans',
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/confirmation': (context) => const ConfirmationMessagePage(),
        '/home': (context) => const HomePage(),
        '/appointment': (context) => const AppointmentPage(),
        '/prescription': (context) => const PrescriptionPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
