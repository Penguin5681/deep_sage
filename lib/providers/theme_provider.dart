import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';

/// A provider class that manages the application theme state.
///
/// This class handles theme mode persistence using Hive storage
/// and provides methods to toggle between light and dark themes.
/// It extends [ChangeNotifier] to notify listeners when theme changes occur.
class ThemeProvider extends ChangeNotifier {
  /// Key used to store the theme mode in the Hive box.
  static const String themeKey = 'themeMode';

  /// Hive box instance for persistent storage.
  /// Uses the box name from environment variables.
  Box box = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// Current theme mode of the application.
  /// Defaults to system theme.
  ThemeMode _themeMode = ThemeMode.system;

  /// Constructor for ThemeProvider.
  /// Loads the saved theme from persistent storage on initialization.
  ThemeProvider() {
    loadThemeFromPrefs();
  }

  /// Getter for the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Toggles between light and dark theme modes.
  ///
  /// If the current theme is light, it changes to dark and vice versa.
  /// After toggling, it saves the new theme to persistent storage
  /// and notifies listeners about the change.
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    saveThemeToPrefs();
    notifyListeners();
  }

  /// Loads the saved theme mode from persistent storage.
  ///
  /// If a theme mode is found in storage, it updates the current theme
  /// and notifies listeners. Otherwise, keeps the default theme.
  void loadThemeFromPrefs() {
    final savedTheme = box.get(themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values[savedTheme];
      notifyListeners();
    }
  }

  /// Saves the current theme mode to persistent storage.
  ///
  /// Stores the theme mode index in the Hive box using the [themeKey].
  void saveThemeToPrefs() {
    box.put(themeKey, _themeMode.index);
  }
}
