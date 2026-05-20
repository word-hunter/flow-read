const String englishApostrophePattern =
    r"['\u2019\u2018\u201B\u02BC\uFF07\u00B4`]";

final RegExp englishWordPattern = RegExp(
  '[a-zA-Z]+(?:$englishApostrophePattern[a-zA-Z]+)*',
);

final RegExp _englishApostropheLike = RegExp(englishApostrophePattern);

String normalizeEnglishApostrophes(String value) {
  return value.replaceAll(_englishApostropheLike, "'");
}

bool hasEnglishApostrophe(String value) {
  return normalizeEnglishApostrophes(value).contains("'");
}

String? canonicalEnglishContraction(
  String word, {
  String? Function(String word)? originFor,
}) {
  final original = normalizeEnglishApostrophes(word).toLowerCase().trim();
  var current = original;
  if (current.isEmpty) return null;

  const directForms = {
    "can't": 'can',
    'cannot': 'can',
    "won't": 'will',
    "shan't": 'shall',
    "ain't": 'be',
    "ma'am": 'madam',
    "o'clock": 'clock',
    "y'all": 'you',
    'tis': 'it',
    'twas': 'it',
    'twere': 'it',
    'til': 'until',
  };

  for (var depth = 0; depth < 5; depth++) {
    final directBase = directForms[current];
    if (directBase != null) {
      return originFor?.call(directBase) ?? directBase;
    }

    if (!current.contains("'")) {
      return current == original ? null : current;
    }

    final base = _stripContractionSuffix(current);
    if (base == null || base == current) {
      return current == original ? null : current;
    }

    current = originFor?.call(base) ?? base;
  }

  return current == original ? null : current;
}

String? _stripContractionSuffix(String word) {
  if (word.endsWith("n't") && word.length > 3) {
    return word.substring(0, word.length - 3);
  }

  const suffixes = ["'re", "'ve", "'ll", "'d", "'m", "'s"];
  for (final suffix in suffixes) {
    if (word.endsWith(suffix) && word.length > suffix.length) {
      return word.substring(0, word.length - suffix.length);
    }
  }

  return null;
}
