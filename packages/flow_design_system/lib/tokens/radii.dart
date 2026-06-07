abstract class RadiiPrimitives {
  List<double> get radiusScale;

  double get none;
  double get xs;
  double get sm;
  double get md;
  double get lg;
  double get xl;
  double get pill;
}

class _DefaultRadiiPrimitives implements RadiiPrimitives {
  const _DefaultRadiiPrimitives();

  @override
  List<double> get radiusScale => const <double>[
    0,
    2,
    4,
    8,
    12,
    16,
    20,
    24,
    999,
  ];

  @override
  double get none => 0;
  @override
  double get xs => 2;
  @override
  double get sm => 4;
  @override
  double get md => 8;
  @override
  double get lg => 12;
  @override
  double get xl => 16;
  @override
  double get pill => 999;
}

const RadiiPrimitives defaultRadiiPrimitives = _DefaultRadiiPrimitives();
