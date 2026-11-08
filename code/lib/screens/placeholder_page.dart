// Temporary content for screens that will be implemented in the next stage.

import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {

  final IconData icon;
  final String description;

  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 75,
              color: const Color(0xFF397D78),
            ),

            const SizedBox(height: 20),

            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
