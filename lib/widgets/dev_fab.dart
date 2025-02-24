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
    void navigateSomewhere(Widget screen) {
      if (parentContext.mounted) {
        Navigator.push(
          parentContext,
          MaterialPageRoute(builder: (BuildContext context) => screen),
        );
      }
    }

    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      children: [
        SpeedDialChild(
          child: Icon(Icons.brightness_6),
          label: 'Switch Theme',
          onTap: () {
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
      ],
    );
  }
}
