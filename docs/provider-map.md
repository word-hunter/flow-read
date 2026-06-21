# Flow Read Provider Map

> @source lib/providers/reading/services_provider.dart lib/providers/settings_provider.dart lib/providers/reading/ai_notifier.dart packages/flow_ai/lib/src/ai_assistant_action_registry.dart packages/flow_ai/lib/src/ai_assistant_controller.dart

Last updated: 2026-06-15

## Provider 层级

```
ProviderScope
├── settingsProvider                    // ChangeNotifierProvider<SettingsService>
├── backupProvider                      // ChangeNotifierProvider<BackupService>
├── rssProvider                         // ChangeNotifierProvider<RssProvider>
└── readingProvider                     // ChangeNotifierProvider<ReadingProvider>
    ├── currentBookProvider             // facade
    ├── bookshelfProvider               // facade
    ├── readingConfigProvider           // facade
    ├── readingTimeProvider             // facade
    ├── vocabularyProvider              // facade
    ├── wordLookupProvider              // facade
    ├── textSelectionProvider           // facade
    ├── readingSearchProvider           // facade
    ├── bookmarkProvider                // facade
    ├── aiProvider                      // facade
    └── learningProvider                // facade
```

## ReadingProvider（核心，~2177 行）

**文件**：`lib/providers/reading_provider.dart`

### 管理的状态域

| 域 | 字段/Types | 公开方法 |
|----|-----------|---------|
| **书籍** | `currentBook`, `currentBookMetadata`, `currentBookChapters`, `currentChapterIndex` | `openBook()`, `closeBook()`, `importEpubFromPath/Bytes()`, `nextChapter()`, `previousChapter()` |
| **章节** | `currentChapter`, `currentChapterContentBlocks`, `chapterScrollOffset` | `gotoChapter()`, `setChapterScrollOffset()` |
| **查词** | `selectedWord`, `selectedWordLookupResult`, `wordLookupHistory`, `isLoadingWord`, `visualDefinition`, `isLoadingVisualHint` | `lookupWord()`, `lookupRelatedWord()`, `goBackWordLookup()`, `clearWordLookup()` |
| **阅读配置** | `readingConfig` (font/theme/spacing) | `setFontSize()`, `setFontFamily()`, `setLineHeight()`, `setPageMargins()` |
| **搜索** | `searchResults`, `currentSearchQuery` | `searchInChapter()`, `searchInBook()`, `clearSearch()` |
| **书签** | `bookmarks`, `wordBookmarks` | `addBookmark()`, `removeBookmark()`, `toggleWordBookmark()` |
| **AI** | `aiSummary`, `aiChapterPreview`, `aiPractice`, `aiTextAnalysis`, `aiTranslation`, `aiWordAnalysis`, `chapterAIStatus`, `chapterAISummaryCoverage` | `generateChapterSummary()`, `analyzeSelectedText()`, `translateSelectedText()`, `analyzeWord()` |
| **词汇** | `userVocab`, `aggregatedVocabulary`, `wordLevelInfo` | `markWordKnown()`, `markWordLearning()`, `markWordUnknown()`, `getWordStatus()` |
| **分析** | `analysisResult`, `chapterDifficulty`, `bookDifficulty` | `analyzeChapter()`, `computeBookDifficulty()` |
| **阅读时间** | `readingTimeSeconds`, `dailyReadingGoal` | `startReadingTimer()`, `stopReadingTimer()` |
| **学习** | `learningItems`, `chapterLearningReport`, `weeklyLearningSummary` | `createLearningItem()`, `updateLearningItem()` |
| **发音** | — | `pronounceWord()` |
| **复习** | `reviewQuestions`, `reviewProgress` | `generateReviewQuestions()`, `submitReviewAnswer()` |

### 1.7.0 迁移目标

已新增 `AIAssistantActionRegistry`，负责根据 `AIContextSnapshot` 判断动作可用性，并把统一动作路由到现有 `PromptBuilder` 方法。
已新增 `AIAssistantController` / `AIActionController` 生命周期基础类；阅读器右侧 `AIAssistantPanel` 已开始使用轻量 session/message 状态承载动作结果和连续追问。旧 `ReadingProvider` 中的 AI 字段仍按下表逐步收敛。
已新增 `contextRetrievalServiceProvider`，由 `AIAssistantController.contextResolver` 在动作执行前注入 Reading Memory 学习上下文。
已新增 `reviewCandidateServiceProvider`，由 `ReadingMemoryService` 在保存解释、重复查词和标记学习中时生成复习候选。
已新增 `knowledgeRetentionServiceProvider`，统一处理 SourceScope 归档、保留学习记忆、仅保留元数据和彻底删除相关记忆。
已新增 `readingMemoryOverlayServiceProvider`，由 ReaderPage 为当前章节构造只读 Reading Memory Overlay 投影，供正文渲染层消费。

以下 AI 状态将从 `ReadingProvider` 中迁出至 `AIActionController`：

| 迁移字段 | 新位置 |
|----------|--------|
| `_aiTextAnalysis` + `_isAnalyzingText` | `AIActionController` |
| `_aiTranslation` + `_isTranslatingText` | `AIActionController` |
| `_aiWordAnalysis` + `_isAnalyzingWord` | `AIActionController` |

**保留字段**（有 chapter-level 缓存依赖）：
- `_aiSummary`, `_aiChapterPreview`, `_aiPractice`
- `_chapterAIStatus`, `_chapterAISummaryCoverage`

### 全局快捷访问

```dart
// reading_provider.dart 中的便捷 getter
String get currentBookId => _currentBookMetadata?.id ?? '';
LanguageModule get activeLanguageModule =>
    LanguageRegistry.instance.get(_activeLanguageCode) ?? const EnglishLanguageModule();
String get _activeLanguageCode =>
    _currentBookMetadata?.effectiveSourceLanguage ?? settings.activeSourceLanguage;
```

## SettingsService

**文件**：`lib/services/settings_service.dart`

### 管理的配置项

| 分类 | 配置项 | 持久化 Key |
|------|--------|-----------|
| AI | provider, apiKeys, baseUrls, models, usageStats | `aiProviderId`, `aiApiKeys`, `aiBaseUrls`, `aiModels` |
| 主题 | themeMode, appThemeId, colors | `themeMode`, `appThemeId`, `*Color` |
| 阅读 | dailyReadingGoalMinutes, openTocOnBookOpen, readingConfig defaults | `dailyReadingGoalMinutes`, `openTocOnBookOpen` |
| City 阅读氛围 | cityAtmosphereSettings (theme mode/manual theme/blend mode/scene/intensity/reduceMotion/performance) | `city_atmosphere.*` |
| 词典 | dictionarySources (order + enabled/disabled + supportedLanguages) | `dictionarySources` |
| 备份 | enabled, folderPath, bookmark, interval, secrets | `backup*` |
| 实验 | rss, review | `enabledExperimentalFeatures` |
| 语言 | activeSourceLanguage, targetExplanationLanguage | `active_source_language`, `target_explanation_language` |
| 版本 | lastSeenReleaseNotesVersion | `lastSeenReleaseNotesVersion` |

**注意**：`SettingsService` 是唯一的 `ChangeNotifier` 级 settings provider。其他 service 不应该自行持久化设置。

## RssProvider（~423 行）

**文件**：`lib/providers/rss_provider.dart`

| 域 | 字段 | 方法 |
|----|------|------|
| 订阅 | `subscriptions`, `selectedSubscription`, `selectedArticle`, `articles` | `addSubscription()`, `removeSubscription()`, `refreshFeed()`, `refreshAll()` |
| 筛选 | `filter`, `query` | `setFilter(RssArticleFilter)`, `updateArticleQuery()` |
| 文章 | `articleBody` (详情页) | `loadArticleBody()`, `setArticleRead()`, `setArticleFavorite()`, `setArticleReadLater()` |
| 状态 | `loadStatus`, `errorMessage` | loading/empty/error 三态 |
| 存储 | `RssService` 默认使用 `DriftRssRepository` | `rss_subscriptions`, `rss_articles` |

## BackupService

**文件**：`lib/services/backup_service.dart`

| 域 | 方法 |
|----|------|
| 备份 | `backupNow()`, `schedulePeriodicBackup()`, `cancelScheduledBackup()` |
| 恢复 | `importFromZip()`, `importWordHunterData()`, `importSelectedData()` |
| 导出 | `exportDiagnosticReport()` |

## 引入新 Provider 的约定

1. 新的 AI 状态用独立 provider（如 `AIAssistantController`），不塞 `ReadingProvider`
2. 在 `lib/providers/` 中声明 Riverpod provider
3. 用 `ref.read(xProvider)` 获取，`ref.watch(xProvider)` 监听
4. 避免 provider 间循环依赖
