import 'package:flutter/painting.dart';

abstract class ColorPrimitives {
  List<Color> get primaryRamp;
  List<Color> get secondaryRamp;
  List<Color> get tertiaryRamp;
  List<Color> get neutralRamp;
  List<Color> get neutralVariantRamp;
  List<Color> get errorRamp;
}

class _DefaultColorPrimitives implements ColorPrimitives {
  const _DefaultColorPrimitives();

  @override
  List<Color> get primaryRamp => _kDefaultPrimaryRamp;
  @override
  List<Color> get secondaryRamp => _kDefaultSecondaryRamp;
  @override
  List<Color> get tertiaryRamp => _kDefaultTertiaryRamp;
  @override
  List<Color> get neutralRamp => _kDefaultNeutralRamp;
  @override
  List<Color> get neutralVariantRamp => _kDefaultNeutralVariantRamp;
  @override
  List<Color> get errorRamp => _kDefaultErrorRamp;
}

const _kDefaultPrimaryRamp = <Color>[];
const _kDefaultSecondaryRamp = <Color>[];
const _kDefaultTertiaryRamp = <Color>[];
const _kDefaultNeutralRamp = <Color>[];
const _kDefaultNeutralVariantRamp = <Color>[];
const _kDefaultErrorRamp = <Color>[];

const ColorPrimitives defaultColorPrimitives = _DefaultColorPrimitives();
