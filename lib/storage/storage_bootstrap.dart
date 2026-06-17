import 'package:flow_language/english/english.dart';
import 'package:flow_language/flow_language.dart';

import '../models/book_metadata.dart';
import '../models/learning_item.dart';
import '../models/user_vocabulary.dart';
import 'database/app_database.dart';
import 'database/bootstrap.dart';

AppDatabase? _appDatabase;
DatabaseBootstrapSnapshot _bootstrappedSnapshot =
    const DatabaseBootstrapSnapshot.empty();

AppDatabase? get appDatabase => _appDatabase;
Map<String, String> get bootstrappedSettingsValues =>
    Map.unmodifiable(_bootstrappedSnapshot.settingsValues);
String get bootstrappedReadingConfigLanguage =>
    _bootstrappedSnapshot.readingConfigLanguage;
Map<String, String> get bootstrappedReadingConfigValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingConfigValues);
String get bootstrappedBookMetadataLanguage =>
    _bootstrappedSnapshot.bookMetadataLanguage;
List<BookMetadata> get bootstrappedBookMetadataValues =>
    List.unmodifiable(_bootstrappedSnapshot.bookMetadataValues);
String get bootstrappedReadingTimeLanguage =>
    _bootstrappedSnapshot.readingTimeLanguage;
Map<String, int> get bootstrappedReadingTimeValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingTimeValues);
String get bootstrappedWordContextLanguage =>
    _bootstrappedSnapshot.wordContextLanguage;
Map<String, String> get bootstrappedWordContextValues =>
    Map.unmodifiable(_bootstrappedSnapshot.wordContextValues);
String get bootstrappedBookmarkLanguage =>
    _bootstrappedSnapshot.bookmarkLanguage;
Map<String, String> get bootstrappedWordBookmarkValues =>
    Map.unmodifiable(_bootstrappedSnapshot.wordBookmarkValues);
Map<String, String> get bootstrappedReadingBookmarkValues =>
    Map.unmodifiable(_bootstrappedSnapshot.readingBookmarkValues);
String get bootstrappedDictionaryCacheLanguage =>
    _bootstrappedSnapshot.dictionaryCacheLanguage;
Map<String, String> get bootstrappedDictionaryCacheValues =>
    Map.unmodifiable(_bootstrappedSnapshot.dictionaryCacheValues);
Map<String, String> get bootstrappedCharacterRegistryValues =>
    Map.unmodifiable(_bootstrappedSnapshot.characterRegistryValues);
String get bootstrappedUserVocabularyLanguage =>
    _bootstrappedSnapshot.userVocabularyLanguage;
Map<String, UserWordStatus> get bootstrappedUserVocabularyValues =>
    Map.unmodifiable(_bootstrappedSnapshot.userVocabularyValues);
String get bootstrappedLearningItemLanguage =>
    _bootstrappedSnapshot.learningItemLanguage;
List<LearningItem> get bootstrappedLearningItemValues =>
    List.unmodifiable(_bootstrappedSnapshot.learningItemValues);
String get bootstrappedLearningAnalyticsLanguage =>
    _bootstrappedSnapshot.learningAnalyticsLanguage;
Map<String, int> get bootstrappedLearningAnalyticsValues =>
    Map.unmodifiable(_bootstrappedSnapshot.learningAnalyticsValues);

Future<void> bootstrapStorage() async {
  registerFlowReadLanguageModules();
  await _bootstrapDatabase();
}

Future<void> _bootstrapDatabase() async {
  final result = await bootstrapDatabaseStorage();
  if (result == null) return;
  _appDatabase = result.database;
  _bootstrappedSnapshot = result.snapshot;
}

void registerFlowReadLanguageModules() {
  final registry = LanguageRegistry.instance;
  if (registry.get('en') == null) {
    registry.register(const EnglishLanguageModule());
  }
  if (registry.get('ja') == null) {
    registry.register(const JapaneseLanguageModule());
  }
}
