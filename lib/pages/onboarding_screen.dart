import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() {
    return _OnboardingScreenState();
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> pages = [
    OnboardingPage(
      title: 'Welcome,',
      description: 'Track your meals and improve your health!',
      backgroundColor: MyColors.blue,
    ),
    OnboardingPage(
      title: 'Track your meals',
      description:
          'Easily record every meal you eat, adding details like ingredients, servings and calories. Visualize your eating habits and make healthier choices every day.',
      backgroundColor: MyColors.green,
    ),
    OnboardingPage(
      title: 'Calcul your BMI',
      description:
          'Calculate your body mass index (BMI) by entering your weight and height. Track your progress and get personalized recommendations to achieve your health and wellness goals.',
      backgroundColor: MyColors.orange,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: pages,
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPage == pages.length - 1
          ? Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/signup', (Route<dynamic> route) => false);
                },
                child: Text(
                  "Let's get started!",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      color: MyColors.backgroundColor),
                ),
              ))
          : null,
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
