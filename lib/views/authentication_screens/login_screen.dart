import 'package:deep_sage/views/authentication_screens/signup_screen.dart';
import 'package:deep_sage/views/core_screens/dashboard_screen.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:deep_sage/widgets/google_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:flutter/material.dart';
import 'package:progressive_button_flutter/progressive_button_fluttme_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Route _createSignUpRoute() {
    return PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) => const SignupScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Route _createDashboardRoute() {
    return PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) => const DashboardScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

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
      floatingActionButton: DevFAB(parentContext: context),
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
                        await Future.delayed(const Duration(seconds: 5)).then((
                          _,
                        ) {
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                          ).pushReplacement(_createDashboardRoute());
                        });
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
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(_createSignUpRoute());
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Colors.blue),
                          ),
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
