/// 句法角色
enum SlotRole {
  subject,   // 主语
  verb,      // 谓语动词
  object,    // 宾语
  complement,// 补语/表语
  adverbial, // 状语
  modifier,  // 定语/修饰语
  connector, // 连接词
}

/// 从句类型
enum ClauseType {
  main,         // 主句
  relative,     // 关系从句 (which/who/that...)
  adverbial,    // 状语从句 (because/when/if...)
  nominal,      // 名词性从句 (that/what/whether...)
  participial,  // 分词短语
  infinitive,   // 不定式短语
  coordinate,   // 并列分句
}

/// 从句成分槽位 — 从句内的主语/谓语/宾语等
class SlotInfo {
  final SlotRole role;
  final String text;
  final String label; // 中文标签 "主语", "谓语动词", "宾语" ...

  const SlotInfo({
    required this.role,
    required this.text,
    required this.label,
  });
}

/// 一个从句的完整信息
class ClauseInfo {
  final String text;           // 从句原文
  final ClauseType type;       // 从句类型
  final String label;          // 中文标签 "主句", "定语从句 (which)" ...
  final List<SlotInfo> slots;  // 成分拆分
  final String? explanation;   // 可选的解释说明

  const ClauseInfo({
    required this.text,
    required this.type,
    required this.label,
    this.slots = const [],
    this.explanation,
  });
}

/// 一个句子的完整结构分析
class SentenceBreakdown {
  final String original;           // 原句
  final List<ClauseInfo> clauses;  // 从句列表
  final String structureLabel;     // "简单句" / "主从复合句" / "并列句"
  final String explanation;        // 整体解析说明

  const SentenceBreakdown({
    required this.original,
    required this.clauses,
    required this.structureLabel,
    required this.explanation,
  });
}
