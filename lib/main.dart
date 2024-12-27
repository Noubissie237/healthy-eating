import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/pages/account_page.dart';
import 'package:food_app/pages/chat_page.dart';
import 'package:food_app/pages/contact_page.dart';
import 'package:food_app/pages/conversation_page.dart';
import 'package:food_app/pages/onboarding_screen.dart';
import 'package:food_app/pages/recordings_page.dart';
import 'package:food_app/pages/security_page.dart';
import 'package:food_app/pages/settings_page.dart';
import 'package:food_app/pages/signin_page.dart';
import 'package:food_app/pages/signup_page.dart';
import 'package:food_app/pages/home_page.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final isEmpty = await dbHelper.isTableEmpty();

  runApp(MyApp(initialRoute: isEmpty ? '/onboarding' : '/main'));
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
        '/main': (context) => const MainPage(),
        '/recordings': (context) => const RecordingsPage(),
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/contact': (context) => const ContactPage(),
        '/account': (context) => const AccountPage(),
        '/security': (context) => const SecurityPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          return MaterialPageRoute(
            builder: (context) => ChatPage(
              currentUserId: settings.arguments as String? ?? '1',
            ),
          );
        }
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ConversationPage(
              contactName: args['contactName'],
              avatarUrl: args['avatarUrl'],
              conversationId: args['conversationId'],
              currentUserId: args['currentUserId'],
              receiverId: '2',
            ),
          );
        }
        return null;
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
  late List<Widget> _pages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  Future<void> _initializePages() async {
    final userId = await _getUserId();
    setState(() {
      _pages = [
        const HomePage(),
        ChatPage(currentUserId: userId),
        const Center(child: Text('Save')),
        const Center(child: Text('Operations')),
        const SettingsPage(),
      ];
      _isLoading = false;
    });
  }

  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token != null) {
        final Map<String, dynamic> decodedToken = jsonDecode(token);
        final String email = decodedToken['email'];

        final dbHelper = DatabaseHelper();
        final userData = await dbHelper.getUserByEmail(email);

        return userData?['id'] ?? '';
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'ID utilisateur: $e');
    }
    return '';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: 'Save',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Operations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
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
