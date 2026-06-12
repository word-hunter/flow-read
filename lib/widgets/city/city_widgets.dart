import 'package:flutter/material.dart';
import '../../theme/city_theme_tokens.dart';

BoxDecoration cityCardDecoration(BuildContext context) {
  final city = context.city;

  return BoxDecoration(
    color: city.cardSurface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: city.warmBorder),
    boxShadow: [
      BoxShadow(
        color: city.warmShadow,
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

class CityHomeBackground extends StatelessWidget {
  const CityHomeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final city = context.city;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            city.skyTop,
            city.skyMid,
            city.skyBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}
