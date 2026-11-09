import 'package:flutter/material.dart';

// Introduces the app before the user opens the main screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onBegin,
  });

  // The app passes in what should happen when the user taps Begin.
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Let the user scroll to Begin if the screen is too short.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              // Keep the content from stretching too wide in Chrome.
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Campus Companion',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A little structure. More room to learn.',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Organize your courses, focus on your studies, '
                        'and see your progress in one place.',
                  ),
                  const SizedBox(height: 24),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.checklist),
                    title: Text('Stay on top of deadlines'),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.timer_outlined),
                    title: Text('Study at your own pace'),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.insights_outlined),
                    title: Text('Celebrate your progress'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onBegin,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Begin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}