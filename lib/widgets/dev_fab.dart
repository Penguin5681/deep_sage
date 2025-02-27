import 'package:deep_sage/views/core_screens/dashboard_screen.dart';
import 'package:deep_sage/views/onboarding_screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../views/authentication_screens/login_screen.dart';
import '../views/authentication_screens/signup_screen.dart';
import '../views/edit_profile_screen.dart';

class DevFAB extends StatelessWidget {
  final BuildContext parentContext;
  const DevFAB({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isDialOpen = ValueNotifier<bool>(false);
    void navigateSomewhere(Widget screen) {
      isDialOpen.value = false;
      if (parentContext.mounted) {
        Navigator.pushReplacement(
          parentContext,
          MaterialPageRoute(builder: (BuildContext context) => screen),
        );
      }
    }

    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      openCloseDial: isDialOpen,
      closeDialOnPop: true,
      children: [
        SpeedDialChild(
          child: Icon(Icons.brightness_6),
          label: 'Switch Theme',
          onTap: () {
            isDialOpen.value = false;
            Provider.of<ThemeProvider>(
              parentContext,
              listen: false,
            ).toggleTheme();
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.looks_one),
          label: 'Go to Edit Profile',
          onTap: () {
            navigateSomewhere(EditProfileScreen());
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.looks_two),
          label: 'Go To Login Screen',
          onTap: () {
            navigateSomewhere(LoginScreen());
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.looks_3),
          label: 'Go To Sign Up Screen',
          onTap: () {
            navigateSomewhere(SignupScreen());
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.looks_4),
          label: 'Go To Dashboard',
          onTap: () {
            navigateSomewhere(DashboardScreen());
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.looks_5),
          label: 'Trigger Splash Screen',
          onTap: () {
            navigateSomewhere(SplashScreen());
          },
        ),
      ],
    );
  }
}
