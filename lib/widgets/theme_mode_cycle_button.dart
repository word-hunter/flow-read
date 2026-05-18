import 'package:flutter/material.dart';

class ThemeModeCycleButton extends StatelessWidget {
  const ThemeModeCycleButton({
    super.key,
    required this.nextMode,
    required this.onPressed,
    this.color,
    this.iconSize,
  });

  final ThemeMode nextMode;
  final VoidCallback onPressed;
  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_iconFor(nextMode), size: iconSize),
      color: color,
      onPressed: onPressed,
      tooltip: '切换到${_labelFor(nextMode)}',
    );
  }

  static IconData _iconFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.devices_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
  }

  static String _labelFor(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '系统模式',
      ThemeMode.light => '浅色模式',
      ThemeMode.dark => '深色模式',
    };
  }
}
