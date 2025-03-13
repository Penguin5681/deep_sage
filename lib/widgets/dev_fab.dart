import 'package:deep_sage/core/models/hive_models/user_api_model.dart';
import 'package:deep_sage/views/core_screens/dashboard_screen.dart';
import 'package:deep_sage/views/onboarding_screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/adapters.dart';
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
        SpeedDialChild(
          child: Icon(Icons.bug_report),
          label: 'Debug Print ENV variables',
          onTap: () {
            debugPrint('FLUTTER_ENV: ${dotenv.env['FLUTTER_ENV']}');
            debugPrint('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
            debugPrint('SUPABASE_API: ${dotenv.env['SUPABASE_API']}');
            debugPrint('DEV_BASE_URL: ${dotenv.env['DEV_BASE_URL']}');
            debugPrint('PROD_BASE_URL: ${dotenv.env['PROD_BASE_URL']}');
            debugPrint('API_HIVE_BOX_NAME: ${dotenv.env['API_HIVE_BOX_NAME']}');
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.bug_report),
          label: 'Debug Print Hive data',
          onTap: () {
            final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
            for (int i = 0; i < hiveBox.length; i++) {
              final userApiData = hiveBox.getAt(i) as UserApi?;
              if (userApiData != null) {
                debugPrint('Item 1:');
                debugPrint('Kaggle Username: ${userApiData.kaggleUserName}');
                debugPrint('Item 2:');
                debugPrint('Kaggle API Key: ${userApiData.kaggleApiKey}');
              }
            }
          },
        ),
        SpeedDialChild(
          child: Icon(Icons.bug_report),
          label: 'Debug Print Hive data',
          onTap: () {
            final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);
            debugPrint('=== HIVE BOX DATA ===');
            debugPrint('Box name: ${hiveBox.name}');
            debugPrint('Items count: ${hiveBox.length}');

            for (int i = 0; i < hiveBox.length; i++) {
              final item = hiveBox.getAt(i);
              debugPrint('Item $i: ${item.runtimeType}');

              if (item is UserApi) {
                debugPrint('  Kaggle Username: ${item.kaggleUserName}');
                debugPrint(
                  '  Kaggle API Key: ${item.kaggleApiKey.isNotEmpty ? "[REDACTED]" : "empty"}',
                );
              } else {
                debugPrint('  Value: $item');
              }
            }

            debugPrint('\n=== KEY-VALUE PAIRS ===');
            for (var key in hiveBox.keys) {
              final value = hiveBox.get(key);
              debugPrint('Key: $key (${key.runtimeType})');

              if (value is UserApi) {
                debugPrint('  Kaggle Username: ${value.kaggleUserName}');
                debugPrint(
                  '  Kaggle API Key: ${value.kaggleApiKey.isNotEmpty ? "[REDACTED]" : "empty"}',
                );
              } else {
                debugPrint('  Value: $value (${value?.runtimeType})');
              }
            }
          },
        ),
      ],
    );
  }
}
