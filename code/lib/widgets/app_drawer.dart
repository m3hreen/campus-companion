// Drawer navigation shares the same selected index as the bottom bar.
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onPageSelected,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onPageSelected;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  static const List<String> _titles = [
    'Home', 'Academics', 'Study', 'Insights', 'Campus Map', 'Settings',
  ];
  static const List<IconData> _icons = [
    Icons.home_outlined, Icons.menu_book_outlined, Icons.timer_outlined,
    Icons.bar_chart, Icons.map_outlined, Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text('Campus Companion', style: Theme.of(context).textTheme.titleLarge),
                  const Text('Plan your campus day'),
                ],
              ),
            ),
            for (int index = 0; index < _titles.length; index++)
              ListTile(
                leading: Icon(_icons[index]),
                title: Text(_titles[index]),
                selected: selectedIndex == index,
                onTap: () {
                  // Close the drawer before changing the selected page.
                  Navigator.pop(context);
                  onPageSelected(index);
                },
              ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: darkMode,
              onChanged: onDarkModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
