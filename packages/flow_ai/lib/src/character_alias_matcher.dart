class CharacterMergeCandidate {
  final String canonicalName;
  final List<String> aliases;
  final int firstAppearanceChapter;
  final List<String> evidenceSnippets;

  const CharacterMergeCandidate({
    required this.canonicalName,
    required this.aliases,
    required this.firstAppearanceChapter,
    required this.evidenceSnippets,
  });
}

class CharacterMergeSuggestion {
  final String canonicalName;
  final List<String> mergedAliases;
  final double confidence;

  const CharacterMergeSuggestion({
    required this.canonicalName,
    required this.mergedAliases,
    required this.confidence,
  });
}

class CharacterAliasMatchResult {
  final String inputName;
  final String? matchedCanonical;
  final double confidence;

  const CharacterAliasMatchResult({
    required this.inputName,
    this.matchedCanonical,
    this.confidence = 0,
  });
}

abstract class CharacterAliasMatcher {
  const CharacterAliasMatcher();

  CharacterAliasMatchResult matchCanonical(
    String name,
    List<CharacterMergeCandidate> existing,
  );

  List<CharacterMergeSuggestion> findMerges(
    List<CharacterMergeCandidate> candidates,
  );
}

class EnglishAliasMatcher extends CharacterAliasMatcher {
  const EnglishAliasMatcher();

  @override
  CharacterAliasMatchResult matchCanonical(
    String name,
    List<CharacterMergeCandidate> existing,
  ) {
    final normalized = _normalize(name);

    for (final candidate in existing) {
      final candidateNorm = _normalize(candidate.canonicalName);
      if (candidateNorm == normalized) {
        return CharacterAliasMatchResult(
          inputName: name,
          matchedCanonical: candidate.canonicalName,
          confidence: 1.0,
        );
      }

      for (final alias in candidate.aliases) {
        if (_normalize(alias) == normalized) {
          return CharacterAliasMatchResult(
            inputName: name,
            matchedCanonical: candidate.canonicalName,
            confidence: 0.9,
          );
        }
      }

      // Last name only match (e.g., "Potter" matches "Harry Potter")
      if (normalized.contains(' ') ||
          candidateNorm.contains(' ')) {
        final lastName = normalized.split(' ').last;
        final candidateLastName = candidateNorm.split(' ').last;
        if (lastName.length > 2 && lastName == candidateLastName) {
          return CharacterAliasMatchResult(
            inputName: name,
            matchedCanonical: candidate.canonicalName,
            confidence: 0.6,
          );
        }
      }
    }

    return CharacterAliasMatchResult(
      inputName: name,
      confidence: 0,
    );
  }

  @override
  List<CharacterMergeSuggestion> findMerges(
    List<CharacterMergeCandidate> candidates,
  ) {
    final suggestions = <CharacterMergeSuggestion>[];
    final used = <int>{};

    for (var i = 0; i < candidates.length; i++) {
      if (used.contains(i)) continue;
      final a = candidates[i];
      final aNorm = _normalize(a.canonicalName);
      final aLastName = aNorm.split(' ').last;

      for (var j = i + 1; j < candidates.length; j++) {
        if (used.contains(j)) continue;
        final b = candidates[j];
        final bNorm = _normalize(b.canonicalName);
        final bLastName = bNorm.split(' ').last;

        if (aLastName.length > 2 && aLastName == bLastName) {
          suggestions.add(
            CharacterMergeSuggestion(
              canonicalName: a.canonicalName.length >= b.canonicalName.length
                  ? a.canonicalName
                  : b.canonicalName,
              mergedAliases: [b.canonicalName],
              confidence: 0.6,
            ),
          );
          used.add(j);
          break;
        }
      }
    }

    return suggestions;
  }

  String _normalize(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,!?:;]'), '');
  }
}

class JapaneseAliasMatcher extends CharacterAliasMatcher {
  static const _honorifics = [
    'さん', 'くん', 'ちゃん', '様', '先生', '部長',
    '先輩', '後輩', '課長', '社長',
  ];

  const JapaneseAliasMatcher();

  @override
  CharacterAliasMatchResult matchCanonical(
    String name,
    List<CharacterMergeCandidate> existing,
  ) {
    final normalized = _normalizeJapanese(name);

    for (final candidate in existing) {
      final candidateNorm = _normalizeJapanese(candidate.canonicalName);

      if (candidateNorm == normalized) {
        return CharacterAliasMatchResult(
          inputName: name,
          matchedCanonical: candidate.canonicalName,
          confidence: 1.0,
        );
      }

      for (final alias in candidate.aliases) {
        if (_normalizeJapanese(alias) == normalized) {
          return CharacterAliasMatchResult(
            inputName: name,
            matchedCanonical: candidate.canonicalName,
            confidence: 0.9,
          );
        }
      }
    }

    return CharacterAliasMatchResult(
      inputName: name,
      confidence: 0,
    );
  }

  @override
  List<CharacterMergeSuggestion> findMerges(
    List<CharacterMergeCandidate> candidates,
  ) {
    // For Japanese, auto-merges are rare since honorific-stripping
    // can merge different characters (先生 -> multiple people).
    // Return empty; AI resolver handles the rest.
    return const [];
  }

  String _normalizeJapanese(String name) {
    var result = name.trim();
    // Strip honorifics
    for (final honorific in _honorifics) {
      if (result.endsWith(honorific)) {
        result = result.substring(0, result.length - honorific.length);
        break;
      }
    }
    return result.toLowerCase().trim();
  }
}
