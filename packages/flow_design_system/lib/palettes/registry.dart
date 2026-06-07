import 'palette.dart';
import 'classic.dart';
import 'ocean.dart';
import 'forest.dart';
import 'high_contrast.dart';

class PaletteRegistry {
  PaletteRegistry._();

  static final Map<PaletteId, Palette> _palettes = {
    PaletteId.classic: const ClassicPalette(),
    PaletteId.ocean: const OceanPalette(),
    PaletteId.forest: const ForestPalette(),
    PaletteId.highContrast: const HighContrastPalette(),
  };

  static Palette get(PaletteId id) {
    final palette = _palettes[id];
    if (palette == null) {
      throw ArgumentError('Unknown PaletteId: $id');
    }
    return palette;
  }

  static List<Palette> get all => _palettes.values.toList();
}
