import 'package:deep_sage/widgets/google_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:flutter/material.dart';
import 'package:progressive_button_flutter/progressive_button_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    final backgroundColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.black;
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
            SizedBox(height: 30),
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  PrimaryEditText(
                    placeholderText: 'Email',
                    controller: emailController,
                    obscureText: false,
                    prefixIcon: Icon(Icons.email),
                  ),
                  SizedBox(height: 25),
                  PrimaryEditText(
                    placeholderText: 'Password',
                    controller: passwordController,
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ProgressiveButtonFlutter(
                      height: 40,
                      progressColor: Colors.green,
                      textStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 20.0,
                      ),
                      backgroundColor: backgroundColor,
                      text: 'Login',
                      onPressed: () async {
                        await Future.delayed(const Duration(seconds: 5));
                      },
                      estimatedTime: const Duration(seconds: 5),
                      elevation: 0,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Divider(color: Colors.green, thickness: 1),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Center(
                          child: Text(
                            'or continue with',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.green, thickness: 1),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  GoogleButton(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?  '),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
