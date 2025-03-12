import 'package:deep_sage/views/authentication_screens/signup_screen.dart';
import 'package:deep_sage/views/core_screens/dashboard_screen.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:deep_sage/widgets/google_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:progressive_button_flutter/progressive_button_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Route createScreenRoute(Widget screen, double deltaX, double deltaY) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(deltaX, deltaY);
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
    final supabaseAuthInstance = Supabase.instance.client.auth;

    final _ = dotenv.env['FLUTTER_ENV'];

    final backgroundColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.black;

    Future<void> signIn(String email, String password) async {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

      bool isEmail() {
        return emailRegex.hasMatch(email);
      }

      bool isThePasswordLengthOk() {
        return password.length >= 6;
      }

      if (isEmail() && isThePasswordLengthOk()) {
        try {
          final response = await supabaseAuthInstance.signInWithPassword(
            email: email,
            password: password,
          );
          if (response.session != null) {
            await Hive.box(
              dotenv.env['USER_HIVE_BOX']!,
            ).put('userSessionToken', response.session!.accessToken);
          }

          if (!context.mounted) return;
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: 'Welcome to DeepSage'),
          );
          Navigator.of(
            context,
          ).pushReplacement(createScreenRoute(DashboardScreen(), -1.0, 0.0));
        } catch (e) {
          debugPrint('$e');
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: 'Error Occurred: $e'),
          );
        }
      } else if (!isEmail()) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Invalid Email'),
        );
      } else if (!isThePasswordLengthOk()) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Password too short'),
        );
      } else {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Internal server error occurred!'),
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
                        await signIn(
                          emailController.text,
                          passwordController.text,
                        );
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
                            Navigator.of(context).pushReplacement(
                              createScreenRoute(SignupScreen(), 1.0, 0.0),
                            );
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
