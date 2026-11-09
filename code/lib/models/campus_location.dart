import 'package:flutter/material.dart';

class CampusLocation {
  final String name;
  final String description;
  final String address;
  final String category;
  final IconData icon;

  const CampusLocation({
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.icon,
  });
}