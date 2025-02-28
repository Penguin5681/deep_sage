import 'package:deep_sage/core/config/theme/app_theme.dart';
import 'package:deep_sage/providers/theme_provider.dart';
import 'package:deep_sage/views/onboarding_screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseApi = dotenv.env['SUPABASE_API'] ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseApi);
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
      home: SplashScreen(),
    );
  }
}
