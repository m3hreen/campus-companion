import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';

// Sets up the theme and chooses the first screen.
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

  // Keep rapid theme changes in the order they were made.
  Future<void> _pendingThemeSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // --------------------------------------------------
  // RESTORE THEME AND CHECK HOW THE APP WAS OPENED
  // --------------------------------------------------

  Future<void> _loadTheme() async {
    setState(() {
      _loadingTheme = true;
      _themeLoadFailed = false;
    });

    late final bool savedDarkMode;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      savedDarkMode = prefs.getBool(_darkModeKey) ?? false;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _themeLoadFailed = true;
      });

      return;
    }

    if (!mounted) return;

    int? launchAssignmentId;

    try {
      // Initialize without requesting permission.
      // MainScreen will open the assignment after its saved data loads.
      launchAssignmentId = await NotificationService.instance
          .getLaunchAssignmentId();
    } catch (_) {
      // Notification setup must not prevent the app from opening.
      // MainScreen provides notification error feedback and Retry.
      debugPrint('Could not check the notification launch.');
    }

    if (!mounted) return;

    setState(() {
      _darkMode = savedDarkMode;

      // A notification opens MainScreen directly.
      // Normal launches still show Welcome.
      if (launchAssignmentId != null) {
        _hasBegun = true;
      }

      _loadingTheme = false;
    });
  }

  // --------------------------------------------------
  // APPLY AND SAVE DARK MODE
  // --------------------------------------------------

  void _setDarkMode(bool value) {
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

      // Use consistent shapes and spacing throughout the app.
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

      // Keep failed theme saves visible until a retry succeeds.
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

      // Restore preferences and check notification launch details first.
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
