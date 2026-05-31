class ReaderFontOption {
  const ReaderFontOption({required this.family, required this.label});

  final String family;
  final String label;
}

class ReaderFonts {
  const ReaderFonts._();

  static const systemSerif = 'Serif';
  static const systemSansSerif = 'Sans-serif';
  static const systemMonospace = 'Monospace';
  static const literata = 'Literata';

  static const defaultFamily = systemSerif;

  static const options = <ReaderFontOption>[
    ReaderFontOption(family: systemSerif, label: 'Serif'),
    ReaderFontOption(family: systemSansSerif, label: 'Sans-serif'),
    ReaderFontOption(family: systemMonospace, label: 'Monospace'),
    ReaderFontOption(family: literata, label: 'Literata'),
  ];

  static String normalizeFamily(String? family) {
    final value = family?.trim();
    if (value == null || value.isEmpty) {
      return defaultFamily;
    }
    for (final option in options) {
      if (option.family == value) {
        return option.family;
      }
    }
    return defaultFamily;
  }
}
