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
      title: 'Bienvenue,',
      description: 'Suivez vos repas et améliorez votre santé !',
      backgroundColor: MyColors.blue,
    ),
    OnboardingPage(
      title: 'Suivi de vos repas',
      description:
          'Enregistrez facilement chaque repas que vous consommez, en ajoutant des détails comme les ingrédients, les portions et les calories. Visualisez vos habitudes alimentaires et faites des choix plus sains au quotidien.',
      backgroundColor: MyColors.green,
    ),
    OnboardingPage(
      title: 'Calcul de votre IMC',
      description:
          'Calculez votre indice de masse corporelle (IMC) en entrant votre poids et votre taille. Suivez votre progrès et obtenez des recommandations personnalisées pour atteindre vos objectifs de santé et de bien-être.',
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
                  "commencer",
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
