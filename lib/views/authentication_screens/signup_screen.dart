import 'package:deep_sage/providers/api/auth_api_provider.dart';
import 'package:deep_sage/views/authentication_screens/login_screen.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:deep_sage/widgets/google_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:progressive_button_flutter/progressive_button_flutter.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  Route createScreenRoute(Widget screen, double deltaX, double deltaY) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(deltaX, deltaY);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = dotenv.env['FLUTTER_ENV'];

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    final backgroundColor =
        Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? Colors.black;

    Future<void> validateCredentials(String email, String password, String confirmPassword) async {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (emailRegex.hasMatch(email)) {
        if (password.length > 6 && confirmPassword.length > 6) {
          if (password == confirmPassword) {
            await AuthApiProvider()
                .firebaseUserSignUp(emailController.text, passwordController.text)
                .then((result) {
                  if (!context.mounted) return;
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.success(message: result['message']),
                  );
                  Navigator.of(context).pushReplacement(createScreenRoute(LoginScreen(), 1.0, 0));
                });
          } else {
            if (!context.mounted) return;
            showTopSnackBar(
              Overlay.of(context),
              CustomSnackBar.success(message: 'Passwords do not match'),
            );
          }
        } else {
          if (!context.mounted) return;
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: 'Password too short'),
          );
        }
      } else {
        if (!context.mounted) return;
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: 'Please enter a valid email'),
        );
      }
    }

    return Scaffold(
      floatingActionButton: DevFAB(parentContext: context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Deep Sage',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 35.0, letterSpacing: 4.0),
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
                  SizedBox(height: 25),
                  PrimaryEditText(
                    placeholderText: 'Confirm Password',
                    controller: confirmPasswordController,
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock),
                  ),
                  SizedBox(height: 10),
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
                      text: 'Sign Up',
                      onPressed: () async {
                        if (env == 'production') {
                          await validateCredentials(
                            emailController.text,
                            passwordController.text,
                            confirmPasswordController.text,
                          );
                        } else {
                          Navigator.of(
                            context,
                          ).pushReplacement(createScreenRoute(LoginScreen(), -1.0, 0));
                        }
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
                      Expanded(child: Divider(color: Colors.green, thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Center(
                          child: Text('or continue with', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.green, thickness: 1)),
                    ],
                  ),
                  SizedBox(height: 20),
                  GoogleButton(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?  '),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushReplacement(createScreenRoute(LoginScreen(), -1.0, 0));
                          },
                          child: Text('Sign In', style: TextStyle(color: Colors.blue)),
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
