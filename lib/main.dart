import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/pages/list_meals_page.dart';
import 'package:food_app/pages/maps_page.dart';
import 'package:food_app/pages/statistique_page.dart';
import 'package:provider/provider.dart';
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
  final mealProvider = MealProvider();
  await mealProvider.loadMeals();
  final dbHelper = DatabaseHelper();
  final isEmpty = await dbHelper.isTableEmpty();

  runApp(
    ChangeNotifierProvider(
      create: (context) => mealProvider,
      child: MyApp(initialRoute: isEmpty ? '/onboarding' : '/main'),
    ),
  );
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
        '/statistic': (context) => const StatisticsPage(),
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

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  bool _isLoading = true;

  // Ajout des contrôleurs d'animation
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Animer l'icône initiale
    _animationControllers[0].forward();
  }

  Future<void> _initializePages() async {
    final userId = await _getUserId();
    setState(() {
      _pages = [
        const HomePage(),
        ChatPage(currentUserId: userId),
        const ListMealsPage(),
        const MapsPage(),
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
    // Réinitialiser l'animation précédente
    _animationControllers[_selectedIndex].reverse();

    setState(() {
      _selectedIndex = index;
    });

    // Démarrer la nouvelle animation
    _animationControllers[index].forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: List.generate(5, (index) {
              return BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _animations[index],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == index
                          ? Colors.deepPurple.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      [
                        Icons.home_rounded,
                        Icons.chat_rounded,
                        Icons.save_rounded,
                        Icons.location_on_rounded,
                        Icons.settings_rounded,
                      ][index],
                    ),
                  ),
                ),
                label: [
                  'Home',
                  'Chat',
                  'Save',
                  'Maps',
                  'Settings',
                ][index],
              );
            }),
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
