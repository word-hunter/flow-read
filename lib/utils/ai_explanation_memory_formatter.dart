import 'package:flow_ai/flow_ai.dart';

String formatAITextAnalysisForMemory(AITextAnalysis analysis) {
  final lines = <String>[];

  void addLine(String label, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    lines.add('$label：$trimmed');
  }

  void addSection(String title, Iterable<String> values) {
    final items = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) return;
    lines.add(title);
    lines.addAll(items.map((item) => '- $item'));
  }

  addLine('译文', analysis.translation);
  addSection(
    '结构：',
    analysis.structureNotes.map((note) {
      final role = note.role.trim();
      final source = note.source.trim();
      final prefix = [
        if (source.isNotEmpty) source,
        if (role.isNotEmpty) role,
      ].join('｜');
      final explanation = note.explanation.trim();
      return prefix.isEmpty ? explanation : '$prefix：$explanation';
    }),
  );
  addSection(
    '语法：',
    analysis.grammarPoints.map((point) {
      final source = point.source.trim();
      final difficulty = point.difficulty.trim();
      final prefix = [
        if (source.isNotEmpty) source,
        if (difficulty.isNotEmpty) difficulty,
      ].join('｜');
      final explanation = point.explanation.trim();
      return prefix.isEmpty ? explanation : '$prefix：$explanation';
    }),
  );
  addSection(
    '词汇：',
    analysis.vocabularyNotes.map((note) {
      final word = note.word.trim();
      final pos = note.pos.trim();
      final prefix = [
        if (word.isNotEmpty) word,
        if (pos.isNotEmpty) pos,
      ].join('｜');
      final meaning = note.contextMeaning.trim();
      return prefix.isEmpty ? meaning : '$prefix：$meaning';
    }),
  );
  addSection(
    '表达：',
    analysis.expressionNotes.map((note) {
      final source = note.source.trim();
      final meaning = note.meaning.trim();
      final usage = note.usage.trim();
      final detail = [
        if (meaning.isNotEmpty) meaning,
        if (usage.isNotEmpty) usage,
      ].join('；');
      return source.isEmpty ? detail : '$source：$detail';
    }),
  );
  addLine('阅读提示', analysis.readingTip);

  return lines.join('\n');
}

String formatWordAnalysisForMemory(WordAnalysis analysis) {
  final lines = <String>[];

  final pronunciation = analysis.pronunciation.trim();
  if (pronunciation.isNotEmpty) {
    lines.add('发音：$pronunciation');
  }

  final meanings = analysis.meanings
      .map((meaning) {
        final label = meaning.meaning.trim();
        final explanation = meaning.explanation.trim();
        if (label.isEmpty) return explanation;
        if (explanation.isEmpty) return label;
        return '$label：$explanation';
      })
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  if (meanings.isNotEmpty) {
    lines.add('语境释义：');
    lines.addAll(meanings.map((line) => '- $line'));
  }

  final usageTips = analysis.usageTips
      .map((tip) => tip.trim())
      .where((tip) => tip.isNotEmpty)
      .toList(growable: false);
  if (usageTips.isNotEmpty) {
    lines.add('用法提示：');
    lines.addAll(usageTips.map((tip) => '- $tip'));
  }

  final memoryTip = analysis.memoryTip.trim();
  if (memoryTip.isNotEmpty) {
    lines.add('记忆提示：$memoryTip');
  }

  return lines.join('\n');
}
