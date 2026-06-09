import 'package:flutter/material.dart';

class AtmospherePalette {
  final Color paper;
  final Color sky;
  final Color skySoft;
  final Color sunlight;
  final Color rain;
  final Color moon;
  final Color cloud;
  final Color mint;
  final Color coral;
  final Color ink;

  const AtmospherePalette({
    required this.paper,
    required this.sky,
    required this.skySoft,
    required this.sunlight,
    required this.rain,
    required this.moon,
    required this.cloud,
    required this.mint,
    required this.coral,
    required this.ink,
  });

  static const cityLandscapeDay = AtmospherePalette(
    paper: Color(0xFFFFF8EA),
    sky: Color(0xFF2F9BE8),
    skySoft: Color(0xFF5DB8F2),
    sunlight: Color(0xFFF7D77A),
    rain: Color(0xFF8DB7D3),
    moon: Color(0xFFBFC8F2),
    cloud: Color(0xFFFFFDF7),
    mint: Color(0xFFAEDCC0),
    coral: Color(0xFFE9907D),
    ink: Color(0xFF344052),
  );
}
