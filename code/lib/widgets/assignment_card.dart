// Display one assignment and report checkbox changes through a callback.

import 'package:flutter/material.dart';
import '../models/assignment.dart';

class AssignmentCard extends StatelessWidget {

  final Assignment assignment;
  final VoidCallback onToggle;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onToggle,
  });

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,

      margin: const EdgeInsets.only(bottom: 10),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [

            Checkbox(
              value: assignment.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF397D78),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    assignment.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: assignment.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    assignment.course,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [

                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        'Due: ${formatDate(assignment.dueDate)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
