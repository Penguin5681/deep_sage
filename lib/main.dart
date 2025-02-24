import 'package:deep_sage/core/config/theme/app_theme.dart';
import 'package:deep_sage/providers/theme_provider.dart';
import 'package:deep_sage/views/authentication_screens/login_screen.dart';
// import 'package:deep_sage/views/edit_profile_screen.dart';
// import 'package:deep_sage/views/sign_out_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const LoginScreen(),
    );
  }
}
