import 'package:deep_sage/views/authentication_screens/signup_screen.dart';
import 'package:deep_sage/views/core_screens/navigation_rail/dashboard_screen.dart';
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

/// A widget that displays the login screen for DeepSage.
///
/// This screen provides email/password and Google authentication options,
/// allowing users to sign in to their existing accounts.
class LoginScreen extends StatelessWidget {
  /// Creates a login screen widget.
  const LoginScreen({super.key});

  /// Creates a custom page route with slide transitions.
  ///
  /// This method creates a route to navigate to [screen] with a slide animation
  /// defined by [deltaX] and [deltaY] offsets.
  ///
  /// Parameters:
  ///   - [screen]: The destination screen widget
  ///   - [deltaX]: Starting X offset for the slide animation
  ///   - [deltaY]: Starting Y offset for the slide animation
  ///
  /// Returns a [PageRouteBuilder] with the configured transition
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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final _ = dotenv.env['FLUTTER_ENV'];

    /// Handles the sign-in process with email and password.
    ///
    /// This function validates the email format and password length before
    /// attempting to authenticate with Supabase. On successful authentication,
    /// it stores the user session and navigates to the dashboard screen.
    ///
    /// Parameters:
    ///   - [email]: The user's email address
    ///   - [password]: The user's password
    Future<void> signIn(String email, String password) async {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

      /// Validates if the provided string is in email format.
      bool isEmail() {
        return emailRegex.hasMatch(email);
      }

      /// Checks if the password meets the minimum length requirement (6 characters).
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
            final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
            await userBox.put(
              'userSessionToken',
              response.session!.accessToken,
            );
            await userBox.put('loginMethod', 'email');
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkTheme
                    ? [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF2C2C2C),
                      const Color(0xFF2A2626),
                      const Color(0xFF000000),
                    ]
                    : [
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE0E0E0),
                      const Color(0xFFBDBDBD),
                    ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'DeepSage',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color:
                            isDarkTheme
                                ? Colors.white
                                : const Color(0xFF2C5364),
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Empowering Data Science with AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDarkTheme ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            isDarkTheme
                                ? Colors.grey[850]!.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          PrimaryEditText(
                            placeholderText: 'Email',
                            controller: emailController,
                            obscureText: false,
                            prefixIcon: Icon(Icons.email),
                          ),
                          const SizedBox(height: 16),

                          PrimaryEditText(
                            placeholderText: 'Password',
                            controller: passwordController,
                            obscureText: true,
                            prefixIcon: Icon(Icons.lock),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Forgot password functionality
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color:
                                      isDarkTheme
                                          ? Colors.lightBlueAccent
                                          : const Color(0xFF2C5364),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ProgressiveButtonFlutter(
                                height: 50,
                                progressColor: Colors.green,
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20.0,
                                ),
                                backgroundColor: Color(0xff3fb2e7),
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
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color:
                                      isDarkTheme
                                          ? Colors.grey[600]
                                          : Colors.green,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color:
                                        isDarkTheme
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color:
                                      isDarkTheme
                                          ? Colors.grey[600]
                                          : Colors.green,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: GoogleButton(
                              onSignInSuccess: () {
                                Navigator.of(context).pushReplacement(
                                  createScreenRoute(
                                    DashboardScreen(),
                                    -1.0,
                                    0.0,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  color:
                                      isDarkTheme
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                ),
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      createScreenRoute(
                                        SignupScreen(),
                                        1.0,
                                        0.0,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}
