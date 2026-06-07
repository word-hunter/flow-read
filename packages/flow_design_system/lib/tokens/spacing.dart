abstract class SpacingPrimitives {
  List<double> get spacingScale;

  double get xs;
  double get sm;
  double get md;
  double get lg;
  double get xl;
  double get xxl;
}

class _DefaultSpacingPrimitives implements SpacingPrimitives {
  const _DefaultSpacingPrimitives();

  @override
  List<double> get spacingScale => const <double>[
    0,
    4,
    8,
    12,
    16,
    20,
    24,
    32,
    40,
    48,
    64,
    80,
  ];

  @override
  double get xs => 4;
  @override
  double get sm => 8;
  @override
  double get md => 16;
  @override
  double get lg => 24;
  @override
  double get xl => 32;
  @override
  double get xxl => 48;
}

const SpacingPrimitives defaultSpacingPrimitives = _DefaultSpacingPrimitives();
