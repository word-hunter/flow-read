import 'package:flutter/material.dart';

abstract class FlowMenuEntry<T> {
  const FlowMenuEntry();
}

class FlowMenuItem<T> extends FlowMenuEntry<T> {
  const FlowMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.destructive = false,
    this.selected = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool destructive;
  final bool selected;
}

class FlowMenuDivider<T> extends FlowMenuEntry<T> {
  const FlowMenuDivider();
}
