import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/services/word_level_service.dart';
import 'package:flow_read/storage/repositories/word_level_repository.dart';

WordLevelService fakeWordLevelService({
  Iterable<WordLevelInfo> entries = const [],
  LanguageModule? languageModule,
}) {
  return WordLevelService(
    repository: _InMemoryWordLevelRepository(entries),
    languageModule: languageModule ?? const EnglishLanguageModule(),
  );
}

class _InMemoryWordLevelRepository implements WordLevelRepository {
  _InMemoryWordLevelRepository(Iterable<WordLevelInfo> entries)
    : _entries = entries.toList();

  final List<WordLevelInfo> _entries;
  bool _imported = true;

  @override
  Future<void> init() async {}

  @override
  Iterable<WordLevelInfo> get values => _entries;

  @override
  bool get isNotEmpty => _entries.isNotEmpty;

  @override
  bool get imported => _imported;

  @override
  Future<void> addAll(Iterable<WordLevelInfo> entries) async {
    _entries.addAll(entries);
  }

  @override
  Future<void> markImported() async {
    _imported = true;
  }

  @override
  Future<void> close() async {}
}
