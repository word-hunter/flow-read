enum LevelKey {
  p,
  m,
  h,
  cet4,
  cet6,
  gre,
  other,
  n5,
  n4,
  n3,
  n2,
  n1;

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
      case LevelKey.n5:
        return 'JLPT N5';
      case LevelKey.n4:
        return 'JLPT N4';
      case LevelKey.n3:
        return 'JLPT N3';
      case LevelKey.n2:
        return 'JLPT N2';
      case LevelKey.n1:
        return 'JLPT N1';
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
      case LevelKey.n5:
        return 'N5';
      case LevelKey.n4:
        return 'N4';
      case LevelKey.n3:
        return 'N3';
      case LevelKey.n2:
        return 'N2';
      case LevelKey.n1:
        return 'N1';
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
      case LevelKey.n5:
        return 1;
      case LevelKey.n4:
        return 2;
      case LevelKey.n3:
        return 3;
      case LevelKey.n2:
        return 4;
      case LevelKey.n1:
        return 5;
    }
  }

  bool get isJlpt =>
      this == LevelKey.n5 ||
      this == LevelKey.n4 ||
      this == LevelKey.n3 ||
      this == LevelKey.n2 ||
      this == LevelKey.n1;

  String? get languageCode {
    switch (this) {
      case LevelKey.p:
      case LevelKey.m:
      case LevelKey.h:
      case LevelKey.cet4:
      case LevelKey.cet6:
      case LevelKey.gre:
        return 'en';
      case LevelKey.n5:
      case LevelKey.n4:
      case LevelKey.n3:
      case LevelKey.n2:
      case LevelKey.n1:
        return 'ja';
      case LevelKey.other:
        return null;
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
      case 'n5':
        return LevelKey.n5;
      case 'n4':
        return LevelKey.n4;
      case 'n3':
        return LevelKey.n3;
      case 'n2':
        return LevelKey.n2;
      case 'n1':
        return LevelKey.n1;
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
