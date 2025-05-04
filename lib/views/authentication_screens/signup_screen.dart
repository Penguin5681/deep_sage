import 'package:deep_sage/views/authentication_screens/login_screen.dart';
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

/// A screen widget that allows users to sign up for a new account.
///
/// This widget provides fields for email, password, and name registration,
/// with validation to ensure proper input format. It also provides
/// alternative sign-in options such as Google authentication.
class SignupScreen extends StatelessWidget {
  /// Creates a [SignupScreen] widget.
  const SignupScreen({super.key});

  /// Creates a custom page route with slide transition animation.
  ///
  /// [screen] The target screen widget to navigate to.
  /// [deltaX] The horizontal offset for the slide animation.
  /// [deltaY] The vertical offset for the slide animation.
  ///
  /// Returns a [PageRouteBuilder] with the specified transition animation.
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
    final _ = dotenv.env['FLUTTER_ENV'];
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final supabaseAuthInstance = Supabase.instance.client;

    /// Handles the sign-up process with validation and error handling.
    ///
    /// [email] The user's email address.
    /// [password] The user's chosen password.
    /// [confirmPassword] Password confirmation for validation.
    /// [displayName] The user's display name.
    ///
    /// Performs validation checks on inputs and attempts to register
    /// the user with Supabase authentication.
    Future<void> signUp(
      String email,
      String password,
      String confirmPassword,
      String displayName,
    ) async {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

      /// Validates if the provided email matches a standard email format.
      bool isEmail() {
        return emailRegex.hasMatch(email);
      }

      /// Checks if password and confirmPassword fields match.
      bool doesPasswordMatch() {
        return password == confirmPassword;
      }

      /// Validates that the password meets minimum length requirements.
      bool isThePasswordLengthOk() {
        return password.length >= 6;
      }

      if (isEmail() && doesPasswordMatch() && isThePasswordLengthOk()) {
        try {
          var response = await supabaseAuthInstance.auth.signUp(
            email: emailController.text,
            password: passwordController.text,
            data: {'display_name': displayName},
          );

          if (!context.mounted) return;
          if (response.user!.identities!.isEmpty) {
          } else {
            final userBox = Hive.box(dotenv.env['USER_HIVE_BOX']!);
            if (response.session != null) {
              await userBox.put(
                'userSessionToken',
                response.session!.accessToken,
              );
              await userBox.put('loginMethod', 'email');
            }

            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushReplacement(createScreenRoute(LoginScreen(), -1.0, 0.0));
          }
        } catch (e) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: 'Sign Up Error: $e'),
          );
        }
      } else if (!isEmail()) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Invalid Email'),
        );
      } else if (doesPasswordMatch()) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Passwords do not match'),
        );
      } else if (!isThePasswordLengthOk()) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Minimum password length is 6'),
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
                physics: BouncingScrollPhysics(),
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          PrimaryEditText(
                            placeholderText: 'Name',
                            controller: nameController,
                            obscureText: false,
                            prefixIcon: Icon(Icons.person),
                          ),
                          const SizedBox(height: 16),

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
                          const SizedBox(height: 16),

                          PrimaryEditText(
                            placeholderText: 'Confirm Password',
                            controller: confirmPasswordController,
                            obscureText: true,
                            prefixIcon: Icon(Icons.lock_outline),
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
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20.0,
                                ),
                                backgroundColor: const Color(0xff3fb2e7),
                                text: 'Sign Up',
                                onPressed: () async {
                                  await signUp(
                                    emailController.text,
                                    passwordController.text,
                                    confirmPasswordController.text,
                                    nameController.text,
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
                                'Already have an account? ',
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
                                        LoginScreen(),
                                        -1.0,
                                        0.0,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign In',
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
