import 'package:deep_sage/views/authentication_screens/login_screen.dart';
import 'package:deep_sage/widgets/dev_fab.dart';
import 'package:deep_sage/widgets/google_button.dart';
import 'package:deep_sage/widgets/primary_edit_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:progressive_button_flutter/progressive_button_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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

  // TODO: Implement the sign up logic for display name (Optional)
  // Add field for display name in the sign up screen
  // Add display name to the sign up function

  @override
  Widget build(BuildContext context) {
    final _ = dotenv.env['FLUTTER_ENV'];

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // Controller for name
    final TextEditingController nameController = TextEditingController();

    final backgroundColor =
        Theme.of(
          context,
        ).elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
        Colors.black;

    final supabaseAuthInstance = Supabase.instance.client;

    Future<void> signUp(
      String email,
      String password,
      String confirmPassword,
      String displayName, // Add the display name 
    ) async {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      bool isEmail() {
        return emailRegex.hasMatch(email);
      }

      bool doesPasswordMatch() {
        return password == confirmPassword;
      }

      bool isThePasswordLengthOk() {
        return password.length >= 6;
      }

      if (isEmail() && doesPasswordMatch() && isThePasswordLengthOk()) {
        try {
          var response = await supabaseAuthInstance.auth.signUp(
            email: emailController.text,
            password: passwordController.text,
            data: {'display_name': displayName}, // Store display name in metadata
          );
          if (!context.mounted) return;
          if (response.user!.identities!.isEmpty) {
            // showTopSnackBar(
            //   Overlay.of(context),
            //   CustomSnackBar.info(message: 'User already exists'),
            // );
          } else {
            // showTopSnackBar(
            //   Overlay.of(context),
            //   CustomSnackBar.success(message: 'Sign Up Successful'),
            // );
            Navigator.of(
              context,
            ).pushReplacement(createScreenRoute(LoginScreen(), -1.0, 0.0));
          }
        } catch (e) {
          // showTopSnackBar(
          //   Overlay.of(context),
          //   CustomSnackBar.error(message: 'Sign Up Error: $e'),
          // );
        }
      } else if (!isEmail()) {
        // showTopSnackBar(
        //   Overlay.of(context),
        //   CustomSnackBar.error(message: 'Invalid Email'),
        // );
      } else if (doesPasswordMatch()) {
        // showTopSnackBar(
        //   Overlay.of(context),
        //   CustomSnackBar.error(message: 'Passwords do not match'),
        // );
      } else if (!isThePasswordLengthOk()) {
        // showTopSnackBar(
        //   Overlay.of(context),
        //   CustomSnackBar.error(message: 'Minimum password length is 6'),
        // );
      } else {
        // showTopSnackBar(
        //   Overlay.of(context),
        //   CustomSnackBar.error(message: 'Internal server error occurred!'),
        // );
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
                  // Added name field to display name in the settings screen from supabase
                  PrimaryEditText(
                    placeholderText: 'Name',
                    controller: nameController,
                    obscureText: false,
                    prefixIcon: Icon(Icons.person),
                  ),
                  SizedBox(height: 25),
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
                        await signUp(
                          emailController.text,
                          passwordController.text,
                          confirmPasswordController.text, 
                          nameController.text, // Pass the display name
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
                      const Text('Already have an account?  '),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              createScreenRoute(LoginScreen(), -1.0, 0),
                            );
                          },
                          child: Text(
                            'Sign In',
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
