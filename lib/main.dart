import 'package:deep_sage/core/config/theme/app_theme.dart';
import 'package:deep_sage/core/models/hive_models/recent_imports_model.dart';
import 'package:deep_sage/core/models/hive_models/user_api_model.dart';
import 'package:deep_sage/core/services/user_session_service.dart';
import 'package:deep_sage/providers/theme_provider.dart';
import 'package:deep_sage/views/core_screens/navigation_rail/dashboard_screen.dart';
import 'package:deep_sage/views/authentication_screens/login_screen.dart';
import 'package:deep_sage/views/onboarding_screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'core/services/download_overlay_service.dart';
import 'core/services/download_service.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  final appSupportDirectory =
      await path_provider.getApplicationSupportDirectory();

  debugPrint("app data: ${appSupportDirectory.path}");

  Hive.init(appSupportDirectory.path);
  Hive.registerAdapter(UserApiAdapter());
  Hive.registerAdapter(RecentImportsModelAdapter());

  await Hive.openBox(dotenv.env['API_HIVE_BOX_NAME']!);
  await Hive.openBox(dotenv.env['USER_HIVE_BOX']!);
  await Hive.openBox(dotenv.env['RECENT_IMPORTS_HISTORY']!);
  await Hive.openBox('starred_datasets');
  await Hive.openBox('user_preferences');

  // await CacheService().initCacheBox();

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseApi = dotenv.env['SUPABASE_API'] ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseApi);

  // Check if there's an existing valid session
  bool hasValidSession = await checkExistingSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider(create: (_) => DownloadOverlayService()),
      ],
      child: Phoenix(child: MyApp(hasValidSession: hasValidSession)),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasValidSession;

  const MyApp({super.key, this.hasValidSession = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deep Sage',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: hasValidSession ? DashboardScreen() : SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
