import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'Deep Sage',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 35.0,
                letterSpacing: 4.0,
              ),
            ),
            Text(
              'Empowering Data Science with AI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 35.0,
                letterSpacing: 4.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
