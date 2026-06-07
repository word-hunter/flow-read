import 'dart:ui' show FontWeight;

abstract class TypographyPrimitives {
  String? get brandFontFamily;
  String? get displayFontFamily;
  String get uiFontFamily;
  String? get readerFontFamily;
  String? get monoFontFamily;
  List<double> get fontSizeScale;
  List<FontWeight> get fontWeightScale;
  double get lineHeightTight;
  double get lineHeightNormal;
  double get lineHeightRelaxed;
}

class _DefaultTypographyPrimitives implements TypographyPrimitives {
  const _DefaultTypographyPrimitives();

  @override
  String? get brandFontFamily => null;
  @override
  String? get displayFontFamily => null;
  @override
  String get uiFontFamily => 'Roboto';
  @override
  String? get readerFontFamily => null;
  @override
  String? get monoFontFamily => null;

  @override
  List<double> get fontSizeScale => const <double>[
    10,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    40,
    48,
  ];

  @override
  List<FontWeight> get fontWeightScale => const <FontWeight>[
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ];

  @override
  double get lineHeightTight => 1.0;
  @override
  double get lineHeightNormal => 1.5;
  @override
  double get lineHeightRelaxed => 1.75;
}

const TypographyPrimitives defaultTypographyPrimitives =
    _DefaultTypographyPrimitives();
