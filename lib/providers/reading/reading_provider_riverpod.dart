import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../reading_provider.dart';
import '../settings_provider.dart';
import 'services_provider.dart';

final readingProvider = ChangeNotifierProvider<ReadingProvider>((ref) {
  final provider = ReadingProvider();

  provider.setBookService(ref.read(bookServiceProvider));
  provider.setBookmarkService(ref.read(bookmarkServiceProvider));
  provider.setReadingConfig(ref.read(readingConfigServiceProvider));
  provider.setReadingTime(ref.read(readingTimeServiceProvider));
  provider.setUserVocabulary(ref.read(userVocabularyServiceProvider));
  provider.setWordRepository(ref.read(wordRepositoryProvider));
  provider.setWordLevelService(ref.read(wordLevelServiceProvider));
  provider.setWordContextService(ref.read(wordContextServiceProvider));
  provider.setLearningItemService(ref.read(learningItemServiceProvider));
  provider.setLearningAnalyticsService(
    ref.read(learningAnalyticsServiceProvider),
  );
  provider.setReviewScheduleService(ref.read(reviewScheduleServiceProvider));
  provider.setPronunciationService(ref.read(pronunciationServiceProvider));
  provider.setSentenceAnalyzer(ref.read(sentenceAnalyzerProvider));
  provider.setSettings(ref.read(settingsProvider));
  provider.setAIService(ref.read(aiServiceProvider));
  provider.setAICache(ref.read(aiCacheServiceProvider));

  unawaited(provider.init());
  return provider;
});
