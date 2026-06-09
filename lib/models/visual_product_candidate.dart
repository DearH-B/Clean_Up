import 'package:flutter/material.dart';

class VisualProductCandidate {
  const VisualProductCandidate({
    required this.id,
    required this.categoryName,
    required this.brand,
    required this.displayName,
    required this.formFactor,
    required this.releasePeriod,
    required this.features,
    required this.icon,
  });

  final String id;
  final String categoryName;
  final String brand;
  final String displayName;
  final String formFactor;
  final String releasePeriod;
  final List<String> features;
  final IconData icon;
}
