# Flow Read Service Boundaries

> @source lib/services/ lib/app/app_providers.dart

Last updated: 2026-06-03

## 服务分类

### 1. 阅读核心

| Service | 职责 | 依赖 |
|---------|------|------|
| `BookService` | 书籍 CRUD、封面提取、书籍列表 | Hive `books_{lang}` box |
| `EpubService` | EPUB 解析（epubx 包）、章节提取、图片提取 | `EpubImportSource` |
| `BookmarkService` | 阅读书签 + 单词书签管理 | `word_bookmarks_{lang}`, `reading_bookmarks_{lang}` |
| `ReadingConfigService` | 字体、字号、行高、边距、主题持久化 | `reading_config_{lang}` |
| `ReadingTimeService` | 阅读时长跟踪、每日目标检测 | `reading_time_{lang}` |
| `ReadingSearchService` | 全文搜索、搜索结果偏移定位 | `BookService`（获取章节文本） |

### 2. 词典

| Service / Adapter | 职责 | 类型 |
|-------------------|------|------|
| `DictionaryManagerService` | 多源编排、按优先级查词、失败 fallback | Orchestrator |
| `WordNetRepository` | 离线 WordNet（JSON 字典） | Adapter (offline) |
| `CollinsRepository` | 在线 Collins（HTML 解析） | Adapter (online) |
| `LongmanRepository` | 在线 Longman（HTML 解析） | Adapter (online) |
| `DictionaryRepository` | 在线 DictionaryAPI.dev | Adapter (online) |
| `DictionarySourceRegistry` | 创建全部适配器实例 | Factory |
| `DictionaryCacheService` | 查词结果缓存（Hive, 500 条上限） | Cache |
| `DictionarySourceTestService` | 来源连通性测试 | Diagnostics |
| `CompoundWordAnalyzer` | 复合词拆分（`godswood → gods + wood`） | NLP |

查词优先级链：

```
DictionaryManagerService.lookup(word, languageCode)
  → Walker 按 priority 排序的 enabled adapters
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
| `UserVocabularyService` | 用户已知/学习中的单词管理 |
| `WordLevelService` | 单词等级查询（小学/中学/CET4/6/雅思/托福） |
| `WordContextService` | 单词在书中出现位置的上下文 |
| `LearningItemService` | 学习条目持久化 |
| `LearningAnalyticsService` | 查词频率分析、章节报告、周报 |
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
4. **手动 DI**：在 `app_providers.dart` 中组装依赖，不引入 DI 框架
5. **LanguageModule 约束**：新增语言只需实现 `LanguageModule` 接口并注册
