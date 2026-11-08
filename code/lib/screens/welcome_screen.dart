// Begin replaces this route, just like the welcome flow in Lab 7.
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onBegin});
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(28)),
            child: Icon(Icons.school_outlined, size: 64, color: colors.onPrimaryContainer)),
          const SizedBox(height: 32),
          Text('Campus Companion', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('A little structure. More room to learn.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('Organize your courses, focus on your studies, and see your progress in one place.'),
          const SizedBox(height: 24),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.checklist), title: Text('Stay on top of deadlines')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.timer_outlined), title: Text('Study at your own pace')),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.insights_outlined), title: Text('Celebrate your progress')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: onBegin, icon: const Icon(Icons.arrow_forward), label: const Text('Begin'))),
        ],
      )),
    ))));
  }
}
