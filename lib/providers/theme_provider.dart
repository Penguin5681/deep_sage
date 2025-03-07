import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themeKey = 'themeMode';
  Box box = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    saveThemeToPrefs();
    notifyListeners();
  }

  void loadThemeFromPrefs() {
    final savedTheme = box.get(themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values[savedTheme];
      notifyListeners();
    }
  }

  void saveThemeToPrefs() {
    box.put(themeKey, _themeMode.index);
  }
}
