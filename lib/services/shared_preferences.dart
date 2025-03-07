import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'theme';

  // Obtener el tema guardado
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'light'; // Retorna 'light' si no se ha guardado ningún tema
  }

  // Guardar el tema seleccionado
  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, theme);
  }

  // Cambiar entre tema oscuro y claro
  ThemeData getThemeData(String theme) {
    if (theme == 'dark') {
      return ThemeData.dark();
    } else {
      return ThemeData.light();
    }
  }
}
