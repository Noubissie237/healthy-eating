import 'package:flutter/material.dart';
import 'package:food_app/pages/account_page.dart';
import 'package:food_app/pages/contact_page.dart';
import 'package:food_app/pages/onboarding_screen.dart';
import 'package:food_app/pages/recordings_page.dart';
import 'package:food_app/pages/settings_page.dart';
import 'package:food_app/pages/signin_page.dart';
import 'package:food_app/pages/signup_page.dart';
import 'package:food_app/pages/home_page.dart';
import 'database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final isEmpty = await dbHelper.isTableEmpty();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token');

  Map<String, String> userInfo = {};
  if (token != null) {
    final Map<String, dynamic> decodedToken = jsonDecode(token);
    userInfo = {
      'nom': decodedToken['nom'] ?? 'Inconnu',
      'prenom': decodedToken['prenom'] ?? 'Inconnu',
      'telephone': decodedToken['telephone'] ?? 'Inconnu',
      'email': decodedToken['email'] ?? 'Inconnu',
      'taille': decodedToken['taille']?.toString() ?? 'Inconnu',
      'poids': decodedToken['poids']?.toString() ?? 'Inconnu',
    };
  }

  runApp(MyApp(
      initialRoute: isEmpty ? '/onboarding' : '/main', userInfo: userInfo));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, String> userInfo;

  const MyApp({required this.initialRoute, required this.userInfo, super.key});

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
        '/main': (context) => const MainPage(),
        '/recordings': (context) => const RecordingsPage(),
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/contact': (context) => const ContactPage(),
        '/account': (context) => AccountPage(userInfo: userInfo),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text('Chat')),
    const Center(child: Text('Save')),
    const Center(child: Text('Operations')),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: 'Sauvegardes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Operations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
