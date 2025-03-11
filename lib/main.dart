import 'package:deep_sage/core/config/theme/app_theme.dart';
import 'package:deep_sage/core/models/user_api_model.dart';
import 'package:deep_sage/core/services/cache_service.dart';
import 'package:deep_sage/providers/theme_provider.dart';
import 'package:deep_sage/views/onboarding_screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'core/services/download_service.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  final appSupportDirectory = await path_provider.getApplicationSupportDirectory();

  debugPrint("app data: ${appSupportDirectory.path}");

  Hive.init(appSupportDirectory.path);
  Hive.registerAdapter(UserApiAdapter());

  await Hive.openBox(dotenv.env['API_HIVE_BOX_NAME']!);
  await Hive.openBox(dotenv.env['USER_HIVE_BOX']!);
  await Hive.openBox('starred_datasets');
  await Hive.openBox('user_preferences');

  await CacheService().initCacheBox();

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseApi = dotenv.env['SUPABASE_API'] ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseApi);
  final session = await Hive.box(dotenv.env['USER_HIVE_BOX']!).get('userSession');
  if (session != null) {
    Supabase.instance.client.auth.setSession(session);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
      ],
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
