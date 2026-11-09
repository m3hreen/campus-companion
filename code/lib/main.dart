import 'package:flutter/material.dart';

import 'app.dart';

// Let the tests use CampusCompanionApp by importing this file.
export 'app.dart' show CampusCompanionApp;

// Flutter runs this function first to start the app.
void main() {
  runApp(const CampusCompanionApp());
}