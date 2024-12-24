import 'package:flutter/material.dart';
import 'package:food_app/pages/contact_page.dart';
import 'package:food_app/pages/home_page.dart';
import 'package:food_app/pages/onboarding_screen.dart';
import 'package:food_app/pages/recordings_page.dart';
import 'package:food_app/pages/signin_page.dart';
import 'package:food_app/pages/signup_page.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final isEmpty = await dbHelper.isTableEmpty();

  runApp(MyApp(initialRoute: isEmpty ? '/onboarding' : '/signin'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      title: 'Health Food App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomePage(),
        '/recordings': (context) => const RecordingsPage(),
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/contact': (context) => const ContactPage(),
      },
    );
  }
}
