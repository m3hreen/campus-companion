import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';

// Sets up the app's appearance and decides which screen to show first.
class CampusCompanionApp extends StatefulWidget {
  const CampusCompanionApp({super.key});

  @override
  State<CampusCompanionApp> createState() => _CampusCompanionAppState();
}

class _CampusCompanionAppState extends State<CampusCompanionApp> {
  // Start in light mode and show the welcome screen.
  bool _darkMode = false;
  bool _hasBegun = false;

  // Save the switch setting and tell Flutter to update the app.
  void _setDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  // Show the main screen when the user taps Begin.
  void _begin() {
    setState(() {
      _hasBegun = true;
    });
  }

  // Both themes use the same shapes and spacing, with different colours.
  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF397D78),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F8F7)
          : const Color(0xFF121817),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),

      // Give text fields, buttons, and cards a consistent look.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Companion',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _hasBegun
          ? MainScreen(
        darkMode: _darkMode,
        onDarkModeChanged: _setDarkMode,
      )
          : WelcomeScreen(onBegin: _begin),
    );
  }
}
