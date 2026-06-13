enum LevelKey {
  p,
  m,
  h,
  cet4,
  cet6,
  gre,
  other;

  String get label {
    switch (this) {
      case LevelKey.p:
        return 'Primary School';
      case LevelKey.m:
        return 'Middle School';
      case LevelKey.h:
        return 'High School';
      case LevelKey.cet4:
        return 'CET-4';
      case LevelKey.cet6:
        return 'CET-6';
      case LevelKey.gre:
        return 'GRE';
      case LevelKey.other:
        return 'Other';
    }
  }

  String get shortLabel {
    switch (this) {
      case LevelKey.p:
        return 'P';
      case LevelKey.m:
        return 'M';
      case LevelKey.h:
        return 'H';
      case LevelKey.cet4:
        return 'CET-4';
      case LevelKey.cet6:
        return 'CET-6';
      case LevelKey.gre:
        return 'GRE';
      case LevelKey.other:
        return '∞';
    }
  }

  int get difficultyScore {
    switch (this) {
      case LevelKey.p:
        return 1;
      case LevelKey.m:
        return 2;
      case LevelKey.h:
        return 3;
      case LevelKey.cet4:
        return 4;
      case LevelKey.cet6:
        return 5;
      case LevelKey.gre:
        return 6;
      case LevelKey.other:
        return 7;
    }
  }

  static LevelKey fromString(String key) {
    switch (key) {
      case 'p':
        return LevelKey.p;
      case 'm':
        return LevelKey.m;
      case 'h':
        return LevelKey.h;
      case '4':
        return LevelKey.cet4;
      case '6':
        return LevelKey.cet6;
      case 'g':
        return LevelKey.gre;
      case 'o':
      default:
        return LevelKey.other;
    }
  }
}

class WordLevelInfo {
  final String word;
  final String originForm;
  final int levelIndex;

  const WordLevelInfo({
    required this.word,
    required this.originForm,
    required this.levelIndex,
  });

  LevelKey get level => LevelKey.values[levelIndex];
}
