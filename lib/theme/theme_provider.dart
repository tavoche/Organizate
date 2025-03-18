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

  // Tema claro con los colores personalizados
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue, // Azul principal
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Azul para botones primarios
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: const Color(0xFFADD8E6),
    ),
    // Estilos para las tarjetas
    cardTheme: CardTheme(
      color: Colors.white, // Fondo blanco para las tarjetas en tema claro
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    // Estilos para textos
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black87, // Color oscuro para títulos en tema claro
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.black87, // Color oscuro para subtítulos en tema claro
      ),
      bodyLarge: TextStyle(
        color: Colors.black87, // Color oscuro para texto principal en tema claro
      ),
      bodyMedium: TextStyle(
        color: Colors.black54, // Color gris para texto secundario en tema claro
      ),
    ),
    // Estilos para chips (filtros)
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200]!,
      selectedColor: Colors.blue,
      disabledColor: Colors.grey[300]!,
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    // Estilos para checkboxes
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue;
        }
        return Colors.grey[400]!;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );

  // Tema oscuro con los colores personalizados
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: const Color(0xFFADD8E6),
    ),
    // Estilos para las tarjetas en tema oscuro
    cardTheme: CardTheme(
      color: const Color(0xFF2A2A2A), // Fondo gris oscuro para las tarjetas en tema oscuro
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    // Estilos para textos en tema oscuro
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white, // Color claro para títulos en tema oscuro
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.white, // Color claro para subtítulos en tema oscuro
      ),
      bodyLarge: TextStyle(
        color: Colors.white, // Color claro para texto principal en tema oscuro
      ),
      bodyMedium: TextStyle(
        color: Colors.white70, // Color gris claro para texto secundario en tema oscuro
      ),
    ),
    // Estilos para chips (filtros) en tema oscuro
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF3A3A3A),
      selectedColor: Colors.blue,
      disabledColor: const Color(0xFF2A2A2A),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    // Estilos para checkboxes en tema oscuro
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue;
        }
        return Colors.grey[700]!;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
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

