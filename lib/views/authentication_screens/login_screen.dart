import 'package:deep_sage/widgets/primary_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:deep_sage/widgets/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        child: const Icon(Icons.brightness_6),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25.0),
            ),
            const SizedBox(height: 40),
            PrimaryButton(text: 'Login', onPressed: () {}),
            const SizedBox(height: 40),
            SecondaryButton(onPressed: () {}, text: 'Remove Profile'),
            const SizedBox(height: 20),
            PrimaryEditText(
              placeholderText: 'Enter Email',
              controller: controller,
              obscureText: false,
              prefixIcon: Icon(Icons.lock),
            ),
          ],
        ),
      ),
    );
  }
}
