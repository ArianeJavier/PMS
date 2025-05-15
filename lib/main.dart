import 'package:flutter/material.dart';
import 'package:intimacare_client/home.dart';
import 'package:intimacare_client/services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'verification_page.dart';
import 'prescription_page.dart';
import 'profile.dart';
import 'appointment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print("Application starting...");
  WidgetsFlutterBinding.ensureInitialized();
  print("Flutter binding initialized");

  try {
    // Load environment variables
    await dotenv.load();
    print("Environment variables loaded");

    // Initialize Supabase
    await SupabaseService().initialize();
    print("Supabase initialized successfully");

    // Set up deep link handling
    await setupDeepLinks();
  } catch (e) {
    print("Error during initialization: $e");
  }

  runApp(const IntimaCareApp());
}

Future<void> setupDeepLinks() async {
  try {
    final appLinks = AppLinks();

    // Handle initial link if app was terminated
    final initialUri = await appLinks.getInitialLink();  // Changed from getInitialAppLink
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Listen for incoming links while app is running
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  } catch (e) {
    print("Error setting up deep links: $e");
  }
}

void _handleDeepLink(Uri uri) {
  // Your deep link handling logic here
  print("Deep link received: ${uri.path}");
  // You might want to navigate to specific screens based on the URI
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
      onGenerateRoute: (settings) {
        // Handle deep links with query parameters
        if (settings.name?.startsWith('/email-confirmation') == true) {
          final uri = Uri.parse(settings.name!);
          return MaterialPageRoute(
            builder: (context) => EmailConfirmationPage(deepLinkUri: uri),
          );
        }
        
        // Handle other routes
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignUpPage());
          case '/confirmation':
            return MaterialPageRoute(builder: (context) => const ConfirmationMessagePage());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomePage());
          case '/appointment':
            return MaterialPageRoute(builder: (context) => const AppointmentPage());
          case '/prescription':
            return MaterialPageRoute(builder: (context) => const PrescriptionPage());
          case '/profile':
            return MaterialPageRoute(builder: (context) => const ProfilePage());
          default:
            return MaterialPageRoute(builder: (context) => const LoginPage());
        }
      },
    );
  }
}

class EmailConfirmationPage extends StatefulWidget {
  final Uri? deepLinkUri;
  
  const EmailConfirmationPage({super.key, this.deepLinkUri});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleEmailConfirmation();
  }

  Future<void> _handleEmailConfirmation() async {
  try {
    // Use the deep link URI if provided, otherwise try to get it from the intent
    final uri = widget.deepLinkUri ?? await AppLinks().getInitialLink();  // Changed from getInitialUri
    
    if (uri != null) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      setState(() {
        _isProcessing = false;
      });
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No confirmation link found';
      });
    }
  } catch (e) {
    setState(() {
      _isProcessing = false;
      _errorMessage = e.toString();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Confirmation')),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildSuccessState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 50),
        const SizedBox(height: 20),
        Text(
          'Verification failed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 50),
        const SizedBox(height: 20),
        Text(
          'Email Verified Successfully!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          child: const Text('Continue to App'),
        ),
      ],
    );
  }
}