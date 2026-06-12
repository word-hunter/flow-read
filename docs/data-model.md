# Flow Read Data Model

> @source lib/storage/hive_type_ids.dart lib/models/ packages/flow_ai/lib/src/models/

Last updated: 2026-06-12

## Hive 持久化模型（8 个）

| Type ID | 模型 | Box | 关键字段 |
|---------|------|-----|----------|
| 0 | `BookMetadata` | `books_{lang}` | id, title, author, sourcePath, coverPath, totalChapters, globalProgress, currentChapter, chapterProgress, lastReadAt, difficultyStudyWords, difficultyRatingJson, chapterScrollOffset, **sourceLanguage(15)**, **sourceLanguageOverride(16)**, **languageConfidence(17)**, **targetExplanationLanguage(18)** |
| 1 | `BookmarkedWord` | `word_bookmarks_{lang}` | word, bookId, chapterIndex, context, note, createdAt |
| 2 | `ReadingBookmark` | `reading_bookmarks_{lang}` | chapterIndex, characterOffset, note, label, createdAt |
| 3 | `ReadingConfig` | `reading_config_{lang}`（旧版迁移来源；运行时使用 Drift `reading_config`） | fontSize, fontFamily, lineHeight, themeMode, pageMargins |
| 4 | `WordLevelInfo` | `word_levels` (global) | word, level (enum), origins |
| 10 | `RssFeedSubscription` | `rss_subscriptions` (global) | url, title, description, imageUrl, lastFetchedAt |
| 11 | `LearningItem` | `learning_items_{lang}` | id, type, prompt, answer, note, studyGoal, source, sourceContext, familiarity, createdAt, lastReviewedAt |
| 12 | `BookGlossaryEntry` | `book_glossary` (global) | id, bookId, word, canonicalForm, explanation, sourceContext, createdAt, lastAccessedAt |

**空闲 Type ID**：5, 6, 7, 8, 9, 13+

## 纯内存模型（非 Hive）

| 模型 | 文件 | 用途 |
|------|------|------|
| `Book` | `book.dart` | 内存中的书籍（chapters, cover, language） |
| `Chapter` | `chapter.dart` | 章节内容（title, plainText, contentBlocks） |
| `ContentBlock` | `content_block.dart` | EPUB 渲染块（text / image） |
| `UserWordStatus` | `user_vocabulary.dart` | 枚举：known, learning |
| `UserVocabularyKey` | `user_vocabulary.dart` | 语言感知词汇 key（languageId + canonical） |
| `UserVocabularyEntry` | `user_vocabulary.dart` | 用户词汇状态 entry（status + timestamps + source metadata） |
| `AggregatedVocabulary` | `aggregated_vocabulary.dart` | 跨章节聚合词汇视图（word + languageId） |
| `BookDifficulty` | `book_difficulty.dart` | l1~l5 难度等级 + 评分 |
| `ReadingToken` | `reading_token.dart` | 结构化阅读 token（surface/canonical/languageId/offsets） |
| `TokenizedText` | `reading_token.dart` | 原文、语言和 token 流，用于 reader 渲染和点击定位 |

## AI 相关模型

| 模型 | 用途 |
|------|------|
| `AISummary` | 章节总结（events, characters, vocab, keyTakeaways） |
| `AIChapterPreview` | 读前预览 |
| `AITextAnalysis` | 选中文本分析（structure, grammar, vocabulary, expression） |
| `AIPracticeSet` / `PracticeQuestion` | AI 生成的练习题 |
| `WordAnalysis` | AI 词汇详解（definitions, usage, etymology） |
| `ChapterAIStatus` | 章节 AI 状态机（unconfigured/loading/cacheHit/failed/fallback/generated） |
| `ChapterAISummaryCoverage` | 已生成章节覆盖率 |
| `AIContextSnapshot` | 统一 AI 助手上下文快照 |
| `AIAssistantActionType` | 统一 AI 助手动作枚举 |
| `AIActionResult` | 统一 AI 动作结果 sealed class |
| `AIAssistantSession` | AI 助手轻量会话（当前上下文、消息、更新时间） |
| `AIChatMessage` | AI 助手会话消息（user/assistant、动作、范围、引用） |
| `AIAssistantCitation` | AI 回答引用锚点（来源类型、章节、quote） |
| `AIAutomationSettings` | AI 自动化模式设置 |
| `ReadingInsightProfile` | 运行时阅读画像 |
| `CharacterRegistryEntry` | 人物注册表条目 |

## 语言模块模型

| 接口 | 实现 |
|------|------|
| `Tokenizer` (abstract, includes `tokenizeToTokens`) | `EnglishLanguageModule` |
| `SentenceSplitter` (abstract) | `EnglishLanguageModule` |
| `SyntaxMarkerProvider` (abstract) | `EnglishLanguageModule` |
| `LanguageModule` (合并三个接口) | `EnglishLanguageModule` |

`LanguageRegistry` 是单例，`_modules` map 按 languageCode 存储。

## 1.6.0 待新增模型

| 模型 | Type ID | Box | 状态 |
|------|---------|-----|------|
| `ReadingToken` | 非 Hive | — | 已实现 |
| `TokenizedText` | 非 Hive | — | 已实现 |
| `UserVocabularyEntry` | 非 Hive（JSON value） | `user_vocabulary_{lang}` | 已实现 |
| `UserVocabularyKey(languageId, canonical)` | 非 Hive | — | 已实现 |
| `BookGlossaryEntry` | 12 | `book_glossary` (global) | 已实现 |

## Hive Type ID 约束

```dart
static const reserved = <int>{
  0, // BookMetadata
  1, // BookmarkedWord
  2, // ReadingBookmark
  3, // ReadingConfig
  4, // WordLevelInfo
  10, // RssFeedSubscription
  11, // LearningItem
  12, // BookGlossaryEntry
  // 5-9 free, 13+ free
};
```

每次新增 HiveType 必须：
1. 更新 `hive_type_ids.dart`
2. 更新 `hive_storage.dart:registerFlowReadHiveAdapters()`
3. 更新 `hive_storage.dart:openFlowReadHiveBoxes()`（如需新 box）
4. 运行 `fvm dart run build_runner build`
5. 更新 `test/storage_contract_test.dart`
