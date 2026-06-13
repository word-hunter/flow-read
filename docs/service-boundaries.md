# Flow Read Service Boundaries

> @source lib/services/ lib/providers/ packages/flow_ai/ packages/flow_dictionary/ packages/flow_language/ packages/flow_read_atmosphere/

Last updated: 2026-06-13

## 服务分类

### 1. 阅读核心

| Service | 职责 | 依赖 |
|---------|------|------|
| `BookService` | 书籍 CRUD、封面提取、书籍列表 | Drift `books`（由 Hive `books_{lang}` 迁移） |
| `EpubService` | EPUB core parser 结果到 app `Book` 的映射、章节提取、图片提取 | `epub_reader_core` |
| `EpubParseWorker` | EPUB 文件/字节后台 isolate 解析入口，支持导入解析进度回调与任务取消，避免 UI isolate 执行 ZIP/XML/HTML/CSS 解析 | `Isolate.spawn`, `EpubService` |
| `BookmarkService` | 阅读书签 + 单词书签管理 | Drift `word_bookmarks`, `reading_bookmarks`（由 Hive `word_bookmarks_{lang}` / `reading_bookmarks_{lang}` 迁移） |
| `ReadingConfigService` | 字体、字号、行高、边距、主题持久化 | Drift `reading_config`（由 Hive `reading_config_{lang}` 迁移） |
| `ReadingTimeService` | 阅读时长跟踪、每日目标检测 | Drift `reading_time`（由 Hive `reading_time_{lang}` 迁移） |
| `ReadingSearchService` | 全文搜索、搜索结果偏移定位 | `BookService`（获取章节文本） |

### 2. 词典

| Service / Adapter | 职责 | 类型 |
|-------------------|------|------|
| `DictionaryManagerService` | 多源编排、按 languageCode/support matrix 过滤、按优先级查词、失败 fallback | Orchestrator |
| `WordNetRepository` | 离线 WordNet（JSON 字典） | Adapter (offline) |
| `CollinsRepository` | 在线 Collins（HTML 解析） | Adapter (online) |
| `LongmanRepository` | 在线 Longman（HTML 解析） | Adapter (online) |
| `DictionaryRepository` | 在线 DictionaryAPI.dev | Adapter (online) |
| `DictionarySourceRegistry` | 创建全部适配器实例 | Factory |
| `DictionaryCacheService` | 查词结果缓存（Drift, 500 条上限） | Cache |
| `DictionarySourceTestService` | 来源连通性测试 | Diagnostics |
| `CompoundWordAnalyzer` | 复合词拆分（`godswood → gods + wood`） | NLP |

查词优先级链：

```
DictionaryManagerService.lookup(word, languageCode)
  → Walker 按 priority 排序的 enabled + supportsLanguage(languageCode) adapters
    → Collins → WordNet → DictionaryAPI → Longman
  → 全部失败 → CompoundWordAnalyzer + 全书上下文搜索
```

### 3. AI

| Service / Agent | 职责 |
|-----------------|------|
| `LLMClient` | HTTP 调用 LLM API，支持多 provider（DeepSeek/OpenAI 等），带重试 |
| `AIService` | 封装 LLMClient + PromptBuilder，提供 5 种 AI 能力入口 |
| `PromptBuilder` | 构建 typed system/user prompt，注入 spoiler boundary、language、learningFocus |
| `AICacheService` | 基于文件的 AI 响应缓存，key 含 contentHash/promptVersion/sourceLanguage/outputLanguage |
| `CharacterRegistry` | 角色规范名、别名和用户覆盖管理（Drift `character_registry`） |
| `AIDebugTraceRecorder` | 开发期 AI 请求/缓存 trace JSONL 输出，受 `FLOW_AI_DEBUG_TRACE` 控制 |
| `ChapterAIJob` | 章节级 AI 任务编排（summary/practice），优先读缓存 |
| `ReadingAssistantAgent` | RSS/EPUB/浏览器 AI 辅助 |

AI 调用链：

```
UI 触发 → ReadingProvider._onAnalyzeSelected() / _generateChapterSummary()
  → AIService.analyzeText() / generateSummary()
    → PromptBuilder.buildTextAnalysis() / buildChapterSummary()
    → AICacheService.load() / save()
    → LLMClient.chatCompletion()
```

### 4. 词汇与学习

| Service | 职责 |
|---------|------|
| `UserVocabularyService` | 用户已知/学习中的单词管理（Drift `user_vocabulary`） |
| `WordLevelService` | 单词等级查询（Drift `word_levels`，小学/中学/CET4/6/雅思/托福） |
| `WordContextService` | 单词在书中出现位置的上下文（Drift `word_contexts`） |
| `LearningItemService` | 学习条目持久化（Drift `learning_items`） |
| `LearningAnalyticsService` | 查词频率分析、章节报告、周报（Drift `learning_analytics`） |
| `ReviewScheduleService` | 间隔重复调度 |
| `ReviewService` | 复习题目生成 |

### 5. 语音与发音

| Service | 职责 |
|---------|------|
| `PronunciationService` (abstract) | 发音接口 |
| `FlutterTtsPronunciationService` | Flutter TTS 实现 |

### 6. 语言模块

| 文件 | 类/接口 | 层级 |
|------|---------|------|
| `language_module.dart` | `Tokenizer`, `SentenceSplitter`, `SyntaxMarkerProvider`, `LanguageModule` | 抽象接口 |
| `english_language_module.dart` | `EnglishLanguageModule` | 唯一实现 |
| `language_registry.dart` | `LanguageRegistry` (singleton) | 注册表 |

### 7. 平台与工具

| Service | 职责 |
|---------|------|
| `SettingsService` | 全局设置持久化（`ChangeNotifier`） |
| `flow_read_atmosphere` package | City 时间主题、天空/草地氛围背景、resolver 与 inherited scope；由 app shell 注入，不持有持久化 |
| `BackupService` | 备份/恢复/导入（ZIP 打包） |
| `AppLogger` | JSONL 文件日志（脱敏） |
| `DiagnosticExportService` | 诊断报告 ZIP 导出 |
| `MacPermissionDiagnostics` | macOS 沙盒权限检查 |
| `AppUpdateService` | GitHub releases 更新检查 |
| `AppUpdateInstaller` | macOS 应用替换安装 |
| `ExternalUrlLauncher` | 跨平台 URL 打开 |
| `WebContentService` | 网页抓取 + 可读性提取 |

## 服务依赖图

```
ReadingProvider（总调度）
├── BookService
├── BookmarkService
├── ReadingConfigService
├── ReadingTimeService
├── UserVocabularyService
├── DictionaryManagerService
│   ├── CollinsRepository
│   ├── WordNetRepository
│   ├── DictionaryRepository
│   ├── LongmanRepository
│   └── DictionaryCacheService
├── WordLevelService
├── WordContextService
├── LearningItemService
├── LearningAnalyticsService
├── ReviewScheduleService
├── PronunciationService
├── SettingsService（用于 AI 配置）
├── AIService
│   ├── LLMClient
│   ├── PromptBuilder
│   └── AICacheService
└── ChapterAIJob
    ├── AIService
    └── AICacheService

RssProvider
├── RssService
├── RssFeedDocumentParser
└── WebContentService

SettingsService（独立）
└── Hive settings box

BackupService（独立）
└── Hive boxes + FileSystem
```

## 新增 Service 约定

1. **不要继续塞进 `ReadingProvider`**：新 AI 能力用独立 service/provider/use-case
2. **抽象接口优先**：词典、发音、语言模块都使用 interface + 多实现
3. **Repository 模式**：Hive box 操作通过 `lib/storage/repositories/` 封装的 repository 类
4. **显式 Provider 声明**：在 `lib/providers/` 中声明 Riverpod provider，不引入额外 DI 框架
5. **LanguageModule 约束**：新增语言只需实现 `LanguageModule` 接口并注册
