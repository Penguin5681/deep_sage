import 'package:deep_sage/views/core_screens/dashboard_screen.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:word_carousel/word_carousel.dart';

class SplashScreen extends StatelessWidget {
  final WordCarouselController controller = WordCarouselController();

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final env = dotenv.env['FLUTTER_ENV'];

    Route createDashboardRoute() {
      return PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
    }

    return Scaffold(
      floatingActionButton:
          env == 'development' ? DevFAB(parentContext: context) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                !isDarkMode
                    ? [
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE0E0E0),
                      const Color(0xFFBDBDBD),
                    ]
                    : [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF2C2C2C),
                      const Color(0xFF2A2626),
                      const Color(0xFF000000),
                    ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WordCarousel(
                  controller: controller,
                  fixedText: 'DeepSage',
                  rotatingWords: const [
                    'Analyzing',
                    'Visualizing',
                    'Processing',
                    'Modeling',
                    'Optimizing',
                  ],
                  fixedTextStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : const Color(0xFF2C5364),
                    fontFamily: 'RobotoMono',
                    letterSpacing: 1.5,
                  ),
                  rotatingTextStyle: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color:
                        isDarkMode
                            ? const Color(0xFF2C5364)
                            : const Color(0xFF0F2027),
                    fontFamily: 'RobotoMono',
                    letterSpacing: 1.2,
                  ),
                  stayDuration: const Duration(milliseconds: 2000),
                  animationDuration: const Duration(milliseconds: 800),
                  onTextChanged: (value) {
                    if (value == 4) {
                      Navigator.of(
                        context,
                      ).pushReplacement(createDashboardRoute());
                    }
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  'Empowering Data Science',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 50),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode
                        ? Colors.lightBlueAccent
                        : const Color(0xFF2C5364),
                  ),
                  strokeWidth: 2.0,
                ),
                const SizedBox(height: 20),
                Text(
                  'Initializing AI Core...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}