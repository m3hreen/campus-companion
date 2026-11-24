import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';

// Sets up the app theme and decides which screen to show.
class CampusCompanionApp extends StatefulWidget {
  const CampusCompanionApp({super.key});

  @override
  State<CampusCompanionApp> createState() => _CampusCompanionAppState();
}

class _CampusCompanionAppState extends State<CampusCompanionApp> {
  // --------------------------------------------------
  // APP STATE
  // --------------------------------------------------

  static const String _darkModeKey = 'campus_dark_mode';

  bool _darkMode = false;
  bool _hasBegun = false;
  bool _loadingTheme = true;
  bool _themeLoadFailed = false;
  bool _themeSaveFailed = false;

  // Save rapid theme changes in the same order they were made.
  Future<void> _pendingThemeSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // --------------------------------------------------
  // LOAD AND SAVE DARK MODE
  // --------------------------------------------------

  Future<void> _loadTheme() async {
    setState(() {
      _loadingTheme = true;
      _themeLoadFailed = false;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final bool savedDarkMode = prefs.getBool(_darkModeKey) ?? false;

      if (!mounted) return;

      setState(() {
        _darkMode = savedDarkMode;
        _loadingTheme = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _themeLoadFailed = true;
      });
    }
  }

  void _setDarkMode(bool value) {
    // Apply the change immediately across the app.
    setState(() {
      _darkMode = value;
    });

    _saveTheme();
  }

  void _saveTheme() {
    // Capture this choice before another switch change occurs.
    final bool value = _darkMode;

    _pendingThemeSave = _pendingThemeSave.then((_) async {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final bool saved = await prefs.setBool(_darkModeKey, value);

        if (!saved) {
          throw StateError('Theme could not be saved');
        }

        if (!mounted) return;

        setState(() {
          _themeSaveFailed = false;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _themeSaveFailed = true;
        });
      }
    });
  }

  // --------------------------------------------------
  // WELCOME SCREEN
  // --------------------------------------------------

  // Show Home when Begin is pressed.
  // The welcome screen still appears on each fresh app launch.
  void _begin() {
    setState(() {
      _hasBegun = true;
    });
  }

  // --------------------------------------------------
  // SHARED THEME
  // --------------------------------------------------

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

      // Keep inputs, buttons and cards consistent across screens.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // --------------------------------------------------
  // BUILD THE APP
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Companion',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,

      // Keep save failures visible and allow retrying the current choice.
      builder: (context, child) {
        return Column(
          children: [
            if (_themeSaveFailed)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Your theme could not be saved.'),
                        ),
                        TextButton(
                          onPressed: _saveTheme,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },

      // Load the saved theme before showing the welcome screen.
      home: _loadingTheme
          ? Scaffold(
              body: Center(
                child: _themeLoadFailed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Could not load your theme preference.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadTheme,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            )
          : _hasBegun
          ? MainScreen(darkMode: _darkMode, onDarkModeChanged: _setDarkMode)
          : WelcomeScreen(onBegin: _begin),
    );
  }
}
