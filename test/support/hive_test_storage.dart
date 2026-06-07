import 'dart:io';

import 'package:flow_read/models/book_metadata.dart';
import 'package:flow_read/models/learning_item.dart';
import 'package:flow_read/models/rss_models.dart';
import 'package:flow_read/models/word_level.dart';
import 'package:flow_read/storage/hive_box_names.dart';
import 'package:flow_read/storage/hive_storage.dart';
import 'package:hive/hive.dart';

Future<Directory> initHiveTestStorage(
  String prefix, {
  String? hivePathSuffix,
}) async {
  final tempDir = await Directory.systemTemp.createTemp(prefix);
  final hivePath = hivePathSuffix == null
      ? tempDir.path
      : '${tempDir.path}${Platform.pathSeparator}$hivePathSuffix';

  Hive.init(hivePath);
  registerFlowReadHiveAdapters();
  registerFlowReadLanguageModules();
  return tempDir;
}

Future<void> disposeHiveTestStorage(Directory tempDir) async {
  await Hive.close();
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}

Future<void> openFlowReadTestBoxes() {
  return openFlowReadHiveBoxes();
}

Box<dynamic> settingsBox() => Hive.box<dynamic>(HiveBoxNames.settings);

Box<BookMetadata> booksBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) => Hive.box<BookMetadata>(HiveBoxNames.booksFor(languageCode));

Box<BookMetadata> v1BooksBox() => Hive.box<BookMetadata>(HiveBoxNames.books);

Box<String> userVocabularyBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<String>(HiveBoxNames.userVocabularyFor(languageCode));
}

Box<String> v1UserVocabularyBox() {
  return Hive.box<String>(HiveBoxNames.userVocabulary);
}

Box<String> readingConfigBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<String>(HiveBoxNames.readingConfigFor(languageCode));
}

Box<int> readingTimeBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) => Hive.box<int>(HiveBoxNames.readingTimeFor(languageCode));

Box<WordLevelInfo> wordLevelsBox() {
  return Hive.box<WordLevelInfo>(HiveBoxNames.wordLevels);
}

Box<String> dictionaryCacheBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<String>(HiveBoxNames.dictionaryCacheFor(languageCode));
}

Box<RssFeedSubscription> rssSubscriptionsBox() {
  return Hive.box<RssFeedSubscription>(HiveBoxNames.rssSubscriptions);
}

Box<String> wordContextsBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<String>(HiveBoxNames.wordContextsFor(languageCode));
}

Box<LearningItem> learningItemsBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<LearningItem>(HiveBoxNames.learningItemsFor(languageCode));
}

Box<int> learningAnalyticsBox({
  String languageCode = HiveBoxNames.defaultLanguageCode,
}) {
  return Hive.box<int>(HiveBoxNames.learningAnalyticsFor(languageCode));
}
