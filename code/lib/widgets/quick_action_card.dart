// Reusable tappable dashboard action; the parent supplies the action callback.

import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),

          child: Column(
            children: [

              Icon(
                icon,
                size: 30,
                color: const Color(0xFF397D78),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
