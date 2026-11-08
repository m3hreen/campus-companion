// The root owns theme state so a setting updates every screen.
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

class CampusCompanionApp extends StatefulWidget {
  const CampusCompanionApp({super.key});

  @override
  State<CampusCompanionApp> createState() => _CampusCompanionAppState();
}

class _CampusCompanionAppState extends State<CampusCompanionApp> {
  bool _darkMode = false;

  // Like the lab switches: store the new value, then rebuild.
  void _setDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

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
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
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
      home: MainScreen(darkMode: _darkMode, onDarkModeChanged: _setDarkMode),
    );
  }
}
