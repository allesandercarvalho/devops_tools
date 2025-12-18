import 'package:flutter/material.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final List<NavigationGroup> children;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.children,
  });
}

class NavigationGroup {
  final String title;
  final IconData? icon;
  final List<NavigationChild> items;

  NavigationGroup({
    required this.title,
    this.icon,
    required this.items,
  });
}

class NavigationChild {
  final String id;
  final String title;
  final IconData icon;

  NavigationChild({
    required this.id,
    required this.title,
    required this.icon,
  });
}
