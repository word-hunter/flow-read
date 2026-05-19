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
  return tempDir;
}

Future<void> disposeHiveTestStorage(Directory tempDir) async {
  await Hive.close();
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}

Future<Box<dynamic>> openSettingsTestBox() {
  return Hive.openBox<dynamic>(HiveBoxNames.settings);
}

Future<Box<String>> openUserVocabularyTestBox() {
  return Hive.openBox<String>(HiveBoxNames.userVocabulary);
}

Future<Box<WordLevelInfo>> openWordLevelsTestBox() {
  return Hive.openBox<WordLevelInfo>(HiveBoxNames.wordLevels);
}

Future<Box<LearningItem>> openLearningItemsTestBox() {
  return Hive.openBox<LearningItem>(HiveBoxNames.learningItems);
}

Future<void> openFlowReadTestBoxes() {
  return openFlowReadHiveBoxes();
}

Box<dynamic> settingsBox() => Hive.box<dynamic>(HiveBoxNames.settings);

Box<BookMetadata> booksBox() => Hive.box<BookMetadata>(HiveBoxNames.books);

Box<String> userVocabularyBox() {
  return Hive.box<String>(HiveBoxNames.userVocabulary);
}

Box<String> readingConfigBox() {
  return Hive.box<String>(HiveBoxNames.readingConfig);
}

Box<int> readingTimeBox() => Hive.box<int>(HiveBoxNames.readingTime);

Box<WordLevelInfo> wordLevelsBox() {
  return Hive.box<WordLevelInfo>(HiveBoxNames.wordLevels);
}

Box<String> dictionaryCacheBox() {
  return Hive.box<String>(HiveBoxNames.dictionaryCache);
}

Box<RssFeedSubscription> rssSubscriptionsBox() {
  return Hive.box<RssFeedSubscription>(HiveBoxNames.rssSubscriptions);
}

Box<String> wordContextsBox() {
  return Hive.box<String>(HiveBoxNames.wordContexts);
}

Box<LearningItem> learningItemsBox() {
  return Hive.box<LearningItem>(HiveBoxNames.learningItems);
}
