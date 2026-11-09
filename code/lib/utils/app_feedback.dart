import 'package:flutter/material.dart';

// If a message is already showing, the new one waits its turn.
void showAppFeedback(
    BuildContext context,
    String message, {
      VoidCallback? onUndo,
    }) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),

      // Give the user more time to tap Undo when it's available.
      duration: Duration(seconds: onUndo == null ? 4 : 8),
      persist: false,
      action: onUndo == null
          ? null
          : SnackBarAction(
        label: 'Undo',
        onPressed: onUndo,
      ),
    ),
  );
}
