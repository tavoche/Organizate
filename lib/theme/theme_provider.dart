import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme';
  String _theme = 'light';

  String get theme => _theme;

  ThemeProvider() {
    _loadTheme();
  }

  // Cargar el tema guardado
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _theme = prefs.getString(_key) ?? 'light';
    notifyListeners(); // Notificar a los listeners cuando el tema cambia
  }

  // Guardar el tema seleccionado
  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, theme);
    _theme = theme;
    notifyListeners(); // Notificar a los listeners cuando se guarda el tema
  }

  // Cambiar entre tema oscuro y claro
  ThemeData getThemeData() {
    if (_theme == 'dark') {
      return ThemeData.dark();
    } else {
      return ThemeData.light();
    }
  }
}
