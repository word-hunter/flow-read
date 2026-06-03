import '../models/sentence_breakdown.dart';
import 'language/english_language_module.dart';
import 'language/language_module.dart';
import 'language/language_registry.dart';

// ============================================================
// 抽象接口 —— AI 接入点：实现 SentenceAnalyzer 即可替换
// ============================================================
abstract class SentenceAnalyzer {
  /// 对一段文本做逐句结构分析
  List<SentenceBreakdown> analyze(String text);

  /// 分析器名称（用于 UI 展示）
  String get analyzerName;

  /// 是否使用 AI
  bool get isAI;
}

// ============================================================
// 规则引擎实现（离线，纯 Dart）
// ============================================================
class RuleBasedSentenceAnalyzer implements SentenceAnalyzer {
  RuleBasedSentenceAnalyzer({LanguageModule? languageModule})
    : _languageModule = languageModule;

  final LanguageModule? _languageModule;

  @override
  String get analyzerName => '规则引擎';

  @override
  bool get isAI => false;

  // ---------- 封闭词类静态表 ----------

  static const _pronouns = {
    'i',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'me',
    'him',
    'her',
    'us',
    'them',
    'my',
    'your',
    'his',
    'its',
    'our',
    'their',
    'mine',
    'yours',
    'hers',
    'ours',
    'theirs',
    'myself',
    'yourself',
    'himself',
    'herself',
    'itself',
    'ourselves',
    'yourselves',
    'themselves',
    'this',
    'that',
    'these',
    'those',
    'who',
    'whom',
    'whose',
    'which',
    'what',
    'someone',
    'anyone',
    'everyone',
    'no one',
    'nobody',
    'something',
    'anything',
    'everything',
    'nothing',
  };

  static const _determiners = {
    'the',
    'a',
    'an',
    'this',
    'that',
    'these',
    'those',
    'my',
    'your',
    'his',
    'her',
    'its',
    'our',
    'their',
    'some',
    'any',
    'every',
    'each',
    'all',
    'both',
    'few',
    'many',
    'much',
    'several',
    'no',
  };

  static const _auxiliaries = {
    'be',
    'am',
    'is',
    'are',
    'was',
    'were',
    'been',
    'being',
    'have',
    'has',
    'had',
    'having',
    'do',
    'does',
    'did',
    'will',
    'would',
    'shall',
    'should',
    'can',
    'could',
    'may',
    'might',
    'must',
    'ought',
  };

  static const _prepositions = {
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'about',
    'into',
    'through',
    'during',
    'before',
    'after',
    'above',
    'below',
    'between',
    'under',
    'over',
    'without',
    'within',
    'along',
    'among',
    'upon',
    'across',
    'behind',
    'beyond',
    'toward',
    'towards',
    'against',
    'around',
    'beside',
    'inside',
    'outside',
    'onto',
    'off',
    'up',
    'down',
    'like',
    'as',
    'than',
    'until',
    'since',
  };

  // 从属连词 → 从句类型
  static const _subordinatorType = {
    'which': ClauseType.relative,
    'who': ClauseType.relative,
    'whom': ClauseType.relative,
    'whose': ClauseType.relative,
    'that': ClauseType.relative, // could also be nominal
    'because': ClauseType.adverbial,
    'since': ClauseType.adverbial,
    'although': ClauseType.adverbial,
    'though': ClauseType.adverbial,
    'unless': ClauseType.adverbial,
    'until': ClauseType.adverbial,
    'while': ClauseType.adverbial,
    'whereas': ClauseType.adverbial,
    'when': ClauseType.adverbial,
    'whenever': ClauseType.adverbial,
    'where': ClauseType.adverbial,
    'wherever': ClauseType.adverbial,
    'if': ClauseType.adverbial,
    'even': ClauseType.adverbial,
    'after': ClauseType.adverbial,
    'before': ClauseType.adverbial,
    'as': ClauseType.adverbial,
    'whether': ClauseType.nominal,
    'what': ClauseType.nominal,
  };

  // 并列连词
  static const _coordinators = {'and', 'but', 'or', 'nor', 'yet', 'so'};

  static const _coordinatorLabel = {
    'and': '并列 (and)',
    'but': '转折 (but)',
    'or': '选择 (or)',
    'nor': '并列否定 (nor)',
    'yet': '转折 (yet)',
    'so': '因果 (so)',
  };

  // ---------- 断句 ----------

  LanguageModule get _lm =>
      _languageModule ??
      LanguageRegistry.instance.defaultModule ??
      const EnglishLanguageModule();

  List<String> _splitSentences(String text) {
    final raw = _lm
        .splitSentences(text)
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // 合并单引号/破折号碎片
    final merged = <String>[];
    for (final s in raw) {
      final t = s.trim();
      if (t.isEmpty) continue;
      if (merged.isNotEmpty &&
          (t.startsWith('"') ||
              t.startsWith("'") ||
              t.startsWith('—') ||
              t.startsWith('-'))) {
        merged.last = '${merged.last} $t';
      } else {
        merged.add(t);
      }
    }
    return merged;
  }

  // ---------- 词组抽取 ----------

  List<String> _words(String text) =>
      _lm.wordPattern.allMatches(text).map((m) => m.group(0)!).toList();

  // ---------- 主入口 ----------

  @override
  List<SentenceBreakdown> analyze(String text) {
    final sentences = _splitSentences(text);
    return sentences.map(_analyzeSentence).toList();
  }

  // ---------- 逐句分析 ----------

  SentenceBreakdown _analyzeSentence(String sentence) {
    final clauses = _detectClauses(sentence.trim());

    String structureLabel;
    if (clauses.length == 1 && clauses.first.type == ClauseType.main) {
      structureLabel = '简单句';
    } else if (clauses.any((c) => c.type == ClauseType.coordinate) &&
        !clauses.any(
          (c) =>
              c.type == ClauseType.relative ||
              c.type == ClauseType.adverbial ||
              c.type == ClauseType.nominal,
        )) {
      structureLabel = '并列句';
    } else {
      structureLabel = '主从复合句';
    }

    final explanation = _buildOverallExplanation(clauses, structureLabel);

    return SentenceBreakdown(
      original: sentence.trim(),
      clauses: clauses,
      structureLabel: structureLabel,
      explanation: explanation,
    );
  }

  String _buildOverallExplanation(
    List<ClauseInfo> clauses,
    String structureLabel,
  ) {
    if (clauses.isEmpty) return '无法解析的句子。';

    final mainCount = clauses.where((c) => c.type == ClauseType.main).length;
    final subCount = clauses.length - mainCount;

    if (structureLabel == '简单句') {
      return '这是一个简单句，包含一个主谓结构。';
    }
    if (structureLabel == '并列句') {
      return '这是一个并列句，由并列连词连接 $mainCount 个分句。';
    }
    return '这是一个$structureLabel，包含 $mainCount 个主句和 $subCount 个从句。';
  }

  // ---------- 从句检测 ----------

  List<ClauseInfo> _detectClauses(String sentence) {
    final words = _words(sentence);
    if (words.isEmpty) return [];

    // 先检查并列连词分句
    final coordSplit = _splitAtCoordinators(sentence, words);
    if (coordSplit != null) return coordSplit;

    // 找从属连词 / 关系代词位置
    final markers = <_Marker>[];
    for (final entry in _subordinatorType.entries) {
      final word = entry.key;
      final type = entry.value;
      int searchFrom = 0;
      while (true) {
        final idx = _wordIndexOf(words, word, searchFrom);
        if (idx == -1) break;
        markers.add(_Marker(index: idx, word: word, type: type));
        searchFrom = idx + 1;
      }
    }
    markers.sort((a, b) => a.index.compareTo(b.index));

    if (markers.isEmpty) {
      // 单一主句 — 尝试检测非谓语短语
      return _analyzeSingleClause(sentence);
    }

    // 有从句标记 → 切分
    final clauses = <ClauseInfo>[];
    int wordIdx = 0;

    for (final marker in markers) {
      // 前面部分是主句
      if (marker.index > wordIdx) {
        final mainWords = words.sublist(wordIdx, marker.index);
        final mainText = mainWords.join(' ');
        if (mainText.trim().isNotEmpty) {
          clauses.add(
            _buildClause(
              text: mainText,
              type: ClauseType.main,
              label: clauses.isEmpty ? '主句' : '主句（续）',
            ),
          );
        }
      }

      // 从句部分
      final subWords = words.sublist(marker.index);
      final subText = subWords.join(' ');
      final type = marker.type;
      final label = '${_clauseTypeLabel(type)} (${marker.word})';
      clauses.add(_buildClause(text: subText, type: type, label: label));

      wordIdx = words.length; // 从句取完剩余
      break; // 目前只取第一个从属标记
    }

    if (clauses.isEmpty) {
      clauses.add(
        _buildClause(text: sentence, type: ClauseType.main, label: '主句'),
      );
    }

    return clauses;
  }

  // ---------- 并列句检测 ----------

  List<ClauseInfo>? _splitAtCoordinators(String sentence, List<String> words) {
    // 找最中间的并列连词（不在开头/结尾的）
    int? bestIdx;
    String? bestCoord;
    for (final coord in _coordinators) {
      for (int i = 1; i < words.length - 1; i++) {
        if (words[i].toLowerCase() == coord) {
          bestIdx = i;
          bestCoord = coord;
          break;
        }
      }
      if (bestIdx != null) break;
    }

    if (bestIdx == null || bestCoord == null) return null;

    final leftWords = words.sublist(0, bestIdx);
    final rightWords = words.sublist(bestIdx + 1);

    if (leftWords.isEmpty || rightWords.isEmpty) return null;

    final leftType = _hasSubordinator(leftWords)
        ? ClauseType.main
        : ClauseType.main;
    final rightType = _hasSubordinator(rightWords)
        ? ClauseType.main
        : ClauseType.main;

    return [
      _buildClause(text: leftWords.join(' '), type: leftType, label: '分句 1'),
      ClauseInfo(
        text: bestCoord,
        type: ClauseType.coordinate,
        label: _coordinatorLabel[bestCoord] ?? '并列连词',
        slots: [
          const SlotInfo(role: SlotRole.connector, text: '', label: '连接词'),
        ],
      ),
      _buildClause(text: rightWords.join(' '), type: rightType, label: '分句 2'),
    ];
  }

  bool _hasSubordinator(List<String> words) {
    return words.any((w) => _subordinatorType.containsKey(w.toLowerCase()));
  }

  // ---------- 单一主句 + 非谓语检测 ----------

  List<ClauseInfo> _analyzeSingleClause(String sentence) {
    final clauses = <ClauseInfo>[];

    // 分词短语：句首 -ing 形式
    final participial = _extractParticipial(sentence);
    if (participial != null) {
      clauses.add(
        ClauseInfo(
          text: participial,
          type: ClauseType.participial,
          label: '分词短语',
        ),
      );
      final rest = sentence.substring(participial.length).trim();
      // 去掉前导逗号
      final cleanRest = rest.startsWith(',') ? rest.substring(1).trim() : rest;
      if (cleanRest.isNotEmpty) {
        clauses.add(
          _buildClause(text: cleanRest, type: ClauseType.main, label: '主句'),
        );
      }
      return clauses;
    }

    // 不定式：句首 to + verb
    final infinitive = _extractInfinitive(sentence);
    if (infinitive != null) {
      clauses.add(
        ClauseInfo(
          text: infinitive,
          type: ClauseType.infinitive,
          label: '不定式短语',
        ),
      );
      final rest = sentence.substring(infinitive.length).trim();
      final cleanRest = rest.startsWith(',') ? rest.substring(1).trim() : rest;
      if (cleanRest.isNotEmpty) {
        clauses.add(
          _buildClause(text: cleanRest, type: ClauseType.main, label: '主句'),
        );
      }
      return clauses;
    }

    clauses.add(
      _buildClause(text: sentence, type: ClauseType.main, label: '主句'),
    );
    return clauses;
  }

  String? _extractParticipial(String sentence) {
    final words = _words(sentence);
    if (words.length < 2) return null;
    final first = words[0].toLowerCase();
    if (first.endsWith('ing') && !_auxiliaries.contains(first)) {
      // 找到分词短语的结束位置（逗号或主句动词）
      final commaIdx = sentence.indexOf(',');
      if (commaIdx > 0 && commaIdx < sentence.length ~/ 2) {
        return sentence.substring(0, commaIdx).trim();
      }
      // 找第一个限定动词作为边界
      int? verbIdx;
      for (int i = 1; i < words.length; i++) {
        if (_auxiliaries.contains(words[i].toLowerCase()) ||
            _isLikelyVerb(words[i])) {
          verbIdx = i;
          break;
        }
      }
      if (verbIdx != null && verbIdx > 1) {
        return words.sublist(0, verbIdx).join(' ');
      }
    }
    return null;
  }

  String? _extractInfinitive(String sentence) {
    final words = _words(sentence);
    if (words.length < 3) return null;
    if (words[0].toLowerCase() == 'to' && words[1].length >= 2) {
      final commaIdx = sentence.indexOf(',');
      if (commaIdx > 0 && commaIdx < sentence.length ~/ 2) {
        return sentence.substring(0, commaIdx).trim();
      }
      int? verbIdx;
      for (int i = 2; i < words.length; i++) {
        if (_auxiliaries.contains(words[i].toLowerCase()) ||
            _isLikelyVerb(words[i])) {
          verbIdx = i;
          break;
        }
      }
      if (verbIdx != null && verbIdx > 2) {
        return words.sublist(0, verbIdx).join(' ');
      }
    }
    return null;
  }

  // ---------- 从句构建 ----------

  ClauseInfo _buildClause({
    required String text,
    required ClauseType type,
    required String label,
  }) {
    final slots = _detectSlots(text);
    return ClauseInfo(text: text, type: type, label: label, slots: slots);
  }

  // ---------- 主/谓/宾检测 ----------

  List<SlotInfo> _detectSlots(String clauseText) {
    final words = _words(clauseText);
    if (words.isEmpty) return [];

    final slots = <SlotInfo>[];
    int pos = 0;

    // ---- 找主语 ----
    final subject = _extractSubject(words, pos);
    if (subject != null) {
      slots.add(SlotInfo(role: SlotRole.subject, text: subject, label: '主语'));
      final subjectWords = _words(subject);
      pos = _findEndInWords(words, subjectWords, pos);
    }

    // ---- 找动词 ----
    final verb = _extractVerbGroup(words, pos);
    if (verb != null) {
      slots.add(SlotInfo(role: SlotRole.verb, text: verb, label: '谓语动词'));
      final verbWords = _words(verb);
      pos = _findEndInWords(words, verbWords, pos);
    }

    // ---- 剩余部分 ----
    if (pos < words.length) {
      final remaining = words.sublist(pos).join(' ');

      // 尝试分离宾语和状语
      final objEnd = _findObjectEnd(words, pos);
      if (objEnd > pos) {
        final objText = words.sublist(pos, objEnd).join(' ');
        slots.add(SlotInfo(role: SlotRole.object, text: objText, label: '宾语'));
        if (objEnd < words.length) {
          final advText = words.sublist(objEnd).join(' ');
          slots.add(
            SlotInfo(role: SlotRole.adverbial, text: advText, label: '状语'),
          );
        }
      } else {
        // 全是状语或补语
        if (_startsWithPreposition(words, pos)) {
          slots.add(
            SlotInfo(role: SlotRole.adverbial, text: remaining, label: '状语'),
          );
        } else {
          slots.add(
            SlotInfo(
              role: SlotRole.complement,
              text: remaining,
              label: '补语/状语',
            ),
          );
        }
      }
    }

    return slots;
  }

  String? _extractSubject(List<String> words, int start) {
    if (start >= words.length) return null;

    final lower = words[start].toLowerCase();

    // 代词主语
    if (_pronouns.contains(lower) && !_determiners.contains(lower)) {
      return words[start];
    }

    // 名词短语：determiner? adjective* noun+
    int end = start;
    if (_determiners.contains(words[end].toLowerCase())) {
      end++;
    }
    while (end < words.length && _isLikelyAdjective(words[end])) {
      end++;
    }
    if (end < words.length && _isLikelyNoun(words[end])) {
      end++;
      // 可能的后置修饰
      while (end < words.length && _isLikelyNoun(words[end])) {
        end++;
      }
      return words.sublist(start, end).join(' ');
    }

    // 名词主语（无冠词）
    if (_isLikelyNoun(words[start])) {
      end = start + 1;
      while (end < words.length && _isLikelyNoun(words[end])) {
        end++;
      }
      return words.sublist(start, end).join(' ');
    }

    return null;
  }

  String? _extractVerbGroup(List<String> words, int start) {
    if (start >= words.length) return null;

    int end = start;
    bool foundVerb = false;

    while (end < words.length) {
      final lower = words[end].toLowerCase();
      if (_auxiliaries.contains(lower)) {
        end++;
        continue;
      }
      if (_isLikelyVerb(words[end])) {
        end++;
        foundVerb = true;
        break;
      }
      break;
    }

    // 动词后的副词
    while (end < words.length &&
        words[end].toLowerCase().endsWith('ly') &&
        end - start < 4) {
      end++;
    }

    if (!foundVerb && end == start) {
      // fallback: 把 be 动词或单个可能的动词当作谓语
      if (_auxiliaries.contains(words[start].toLowerCase())) {
        return words[start];
      }
      return null;
    }

    return words.sublist(start, end).join(' ');
  }

  int _findObjectEnd(List<String> words, int start) {
    int i = start;
    // 跳过名词/形容词直到遇到介词或从句标记
    while (i < words.length) {
      final lower = words[i].toLowerCase();
      if (_prepositions.contains(lower)) break;
      if (_subordinatorType.containsKey(lower)) break;
      i++;
    }
    return i;
  }

  bool _startsWithPreposition(List<String> words, int start) {
    if (start >= words.length) return false;
    return _prepositions.contains(words[start].toLowerCase());
  }

  // ---------- 辅助方法 ----------

  int _wordIndexOf(List<String> words, String target, int from) {
    for (int i = from; i < words.length; i++) {
      if (words[i].toLowerCase() == target) return i;
    }
    return -1;
  }

  int _findEndInWords(List<String> allWords, List<String> subWords, int start) {
    int matches = 0;
    for (int i = start; i < allWords.length && matches < subWords.length; i++) {
      if (allWords[i].toLowerCase() == subWords[matches].toLowerCase()) {
        matches++;
      } else {
        break;
      }
    }
    return start + matches;
  }

  bool _isLikelyVerb(String word) {
    if (word.length < 2) return false;
    // 常见动词后缀
    if (word.endsWith('ing')) return true;
    if (word.endsWith('ed')) return true;
    if (word.endsWith('ize') || word.endsWith('ise')) return true;
    if (word.endsWith('ate') && word.length > 4) return true;
    if (word.endsWith('ify')) return true;
    return false;
  }

  bool _isLikelyNoun(String word) {
    if (word.length < 2) return false;
    final lower = word.toLowerCase();
    // 排除明显的动词/形容词/副词
    if (_auxiliaries.contains(lower)) return false;
    if (_prepositions.contains(lower)) return false;
    if (lower.endsWith('ly')) return false;
    if (lower.endsWith('ing') && !lower.endsWith('thing')) return false;
    // 常见名词后缀
    if (lower.endsWith('tion') || lower.endsWith('sion')) return true;
    if (lower.endsWith('ment')) return true;
    if (lower.endsWith('ness')) return true;
    if (lower.endsWith('ity') || lower.endsWith('ty')) return true;
    if (lower.endsWith('ence') || lower.endsWith('ance')) return true;
    if (lower.endsWith('er') || lower.endsWith('or')) return true;
    if (lower.endsWith('ist')) return true;
    if (lower.endsWith('ism')) return true;
    // 首字母大写 → 可能是专有名词
    if (word[0] == word[0].toUpperCase() && word[0] != word[0].toLowerCase()) {
      return true;
    }
    return false;
  }

  bool _isLikelyAdjective(String word) {
    final lower = word.toLowerCase();
    if (lower.endsWith('ous')) return true;
    if (lower.endsWith('ive')) return true;
    if (lower.endsWith('ful')) return true;
    if (lower.endsWith('less')) return true;
    if (lower.endsWith('able') || lower.endsWith('ible')) return true;
    if (lower.endsWith('al') && word.length > 4) return true;
    if (lower.endsWith('ent') || lower.endsWith('ant')) return true;
    if (lower.endsWith('ic') && word.length > 3) return true;
    if (lower.endsWith('ed') && !lower.endsWith('eed')) return true; // 分词形容词
    if (lower.endsWith('ing') && !lower.endsWith('thing')) return true; // 分词形容词
    return false;
  }

  String _clauseTypeLabel(ClauseType type) {
    switch (type) {
      case ClauseType.main:
        return '主句';
      case ClauseType.relative:
        return '定语从句';
      case ClauseType.adverbial:
        return '状语从句';
      case ClauseType.nominal:
        return '名词性从句';
      case ClauseType.participial:
        return '分词短语';
      case ClauseType.infinitive:
        return '不定式短语';
      case ClauseType.coordinate:
        return '并列分句';
    }
  }
}

// ============================================================
// 内部辅助类型
// ============================================================
class _Marker {
  final int index;
  final String word;
  final ClauseType type;
  const _Marker({required this.index, required this.word, required this.type});
}
