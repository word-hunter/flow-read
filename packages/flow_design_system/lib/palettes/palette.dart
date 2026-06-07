import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';

enum PaletteId { classic, ocean, forest, highContrast }

extension PaletteIdLabels on PaletteId {
  String get label {
    switch (this) {
      case PaletteId.classic:
        return '经典';
      case PaletteId.ocean:
        return '海雾';
      case PaletteId.forest:
        return '松林';
      case PaletteId.highContrast:
        return '高对比';
    }
  }

  IconData get icon {
    switch (this) {
      case PaletteId.classic:
        return Icons.auto_stories_outlined;
      case PaletteId.ocean:
        return Icons.water_drop_outlined;
      case PaletteId.forest:
        return Icons.park_outlined;
      case PaletteId.highContrast:
        return Icons.contrast_outlined;
    }
  }
}

abstract class Palette {
  PaletteId get id;
  String get label;
  IconData get icon;

  SemanticColors lightSemantic();
  SemanticColors darkSemantic();

  ColorScheme get lightColorScheme;
  ColorScheme get darkColorScheme;

  ColorPrimitives get primitives;
}
