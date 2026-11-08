// Queue feedback: never hide an existing Undo action when another event arrives.
import 'package:flutter/material.dart';

void showAppFeedback(BuildContext context, String message, {VoidCallback? onUndo}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: onUndo == null ? 4 : 8),
    persist: false,
    action: onUndo == null ? null : SnackBarAction(label: 'Undo', onPressed: onUndo),
  ));
}
