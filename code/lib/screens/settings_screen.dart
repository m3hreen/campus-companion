import 'package:flutter/material.dart';

// Lets the user switch between light and dark mode.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  // The app passes in the current setting and a function to change it.
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Change the appearance of every screen.'),

            // Show the current setting and send back the new value on tap.
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your theme choice lasts for this app session. '
              'Saving preferences will be added with local storage.',
        ),
      ],
    );
  }
}