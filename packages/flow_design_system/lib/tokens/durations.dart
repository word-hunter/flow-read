abstract class DurationPrimitives {
  Duration get instant;
  Duration get fast;
  Duration get normal;
  Duration get slow;
  Duration get verySlow;
  Duration get themeTransition;
  Duration get pageTransition;
}

class _DefaultDurationPrimitives implements DurationPrimitives {
  const _DefaultDurationPrimitives();

  @override
  Duration get instant => Duration.zero;
  @override
  Duration get fast => const Duration(milliseconds: 100);
  @override
  Duration get normal => const Duration(milliseconds: 200);
  @override
  Duration get slow => const Duration(milliseconds: 400);
  @override
  Duration get verySlow => const Duration(milliseconds: 700);
  @override
  Duration get themeTransition => const Duration(milliseconds: 220);
  @override
  Duration get pageTransition => const Duration(milliseconds: 350);
}

const DurationPrimitives defaultDurationPrimitives =
    _DefaultDurationPrimitives();
