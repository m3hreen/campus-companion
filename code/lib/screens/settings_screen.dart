import 'package:flutter/material.dart';

// Displays settings. MainScreen and the app root own the saved values.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    this.remindersEnabled = false,
    this.onRemindersChanged,
    this.updatingReminders = false,
  });

  // Appearance settings are managed by the app root.
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  // MainScreen will handle permission, storage and reminder scheduling.
  final bool remindersEnabled;
  final ValueChanged<bool>? onRemindersChanged;
  final bool updatingReminders;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------
        // APPEARANCE
        // --------------------------------------------------

        Text('Appearance', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Change the appearance of every screen.'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
        ),
        const SizedBox(height: 24),

        // --------------------------------------------------
        // ASSIGNMENT NOTIFICATIONS
        // --------------------------------------------------
        Text('Notifications', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Assignment reminders'),
            subtitle: Text(
              updatingReminders
                  ? 'Updating reminders…'
                  : 'Receive Android notifications at assignment deadlines. '
                        'Android may delay delivery.',
            ),
            value: remindersEnabled,

            // Disable while a permission or scheduling operation is running.
            onChanged: updatingReminders ? null : onRemindersChanged,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enabling reminders asks for notification permission. '
          'Completed assignments do not receive deadline reminders.',
        ),
        const SizedBox(height: 24),

        // --------------------------------------------------
        // LOCAL STORAGE
        // --------------------------------------------------
        Text('Saved on this device', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text(
          'Your courses, assignments, saved study sessions, daily goal '
          'and dark mode preference remain available after restarting '
          'the app.',
        ),
      ],
    );
  }
}
