import 'dart:async';

import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:flutter/material.dart';

import '../authentication_screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Added Animation Controller and Animation
  late AnimationController _controller;
  late Animation<double> _animation;

  // Init method for the Animation Controller
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Timer(const Duration(seconds: 1000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ), // Replace with your next screen
      );
    });
  }

  // Dispose the Animation Controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: DevFAB(parentContext: context),
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? Color(0xff3a3a3a)
              : Colors.white,
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ), // Adjust height to position at the top
              Center(
                child: Container(
                  width: 600,
                  height: 170, // Increased height to avoid overflow
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Icon(
                          Icons.insert_chart, // Example icon, change as needed
                          size: 30, // Decreased size of the icon
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "DeepSage AI",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // SizedBox(height: 2),
                            Text(
                              "Empowering Data Science with AI",
                              style: TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Loading your workspace...",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
