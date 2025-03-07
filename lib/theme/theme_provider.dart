import 'package:flutter/material.dart';
import '../services/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  String _theme = 'light';

  ThemeProvider() {
    _loadTheme();
  }

  String get theme => _theme;
  
  ThemeData get themeData {
    return _theme == 'dark' ? _darkTheme : _lightTheme;
  }

  // Tema claro
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    // Puedes personalizar más aspectos del tema aquí
  );

  // Tema oscuro
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[800],
      foregroundColor: Colors.white,
    ),
    // Puedes personalizar más aspectos del tema aquí
  );

  Future<void> _loadTheme() async {
    _theme = await _themeService.getTheme();
    notifyListeners();
  }

  Future<void> saveTheme(String theme) async {
    _theme = theme;
    await _themeService.saveTheme(theme);
    notifyListeners();
  }
}

