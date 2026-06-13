# Flow Read Storage Contract

> @source lib/storage/hive_box_names.dart lib/storage/hive_type_ids.dart lib/storage/storage_migrations.dart lib/storage/database/app_database.dart lib/storage/database/tables.dart

Last updated: 2026-06-09

## Schema 版本

**当前 Hive 版本：2** | **Drift 版本：1（新增）**

Drift 数据库文件：`flow_read.db`，位于应用文档目录。WAL 模式，外键约束已启用。

## Drift 数据库（新增）

| 表 | DAO | 描述 |
|----|-----|------|
| `books` | BookDao | 书籍元数据 |
| `user_vocabulary` | UserVocabularyDao | 用户词汇状态 |
| `word_bookmarks` | WordBookmarksDao | 单词书签 |
| `reading_bookmarks` | ReadingBookmarksDao | 阅读书签 |
| `reading_config` | ReadingConfigDao | 阅读配置（运行时 source of truth） |
| `reading_time` | ReadingTimeDao | 阅读时长 |
| `dictionary_cache` | DictionaryCacheDao | 词典缓存 |
| `word_contexts` | WordContextDao | 单词例句 |
| `learning_items` | LearningItemDao | 学习条目 |
| `learning_analytics` | LearningAnalyticsDao | 学习分析 |
| `word_levels` | WordLevelDao | 单词等级 |
| `rss_subscriptions` | RssDao | RSS 订阅 |
| `rss_articles` | RssDao | RSS 文章 |
| `book_glossary` | BookGlossaryDao | 书籍生词表 |
| `character_registry` | CharacterRegistryDao | 字符注册 |
| `settings` | SettingsDao | 应用设置 |

启动时通过 `HiveToDriftMigration` 自动从 Hive 迁移数据。迁移成功后会在 Drift
`settings` 表写入 legacy 迁移标记，后续启动默认跳过，避免旧 Hive 数据覆盖新的
Drift 数据。

### Legacy Hive → Drift 迁移标记

| Key | 内容 |
|-----|------|
| `legacy_hive_to_drift_completed_at` | 最近一次完成迁移的 UTC 时间 |
| `legacy_hive_to_drift_source_schema_version` | 导入时的 Hive schema version |
| `legacy_hive_to_drift_source_language` | 导入时的语言分区 |

RSS 文章状态的旧 settings ID 集合缺少 `rss_articles.subscription_id` 外键上下文，
当前迁移只统计扫描量，不写入孤儿 `rss_articles` 行。RSS 运行时已切到
`DriftRssRepository`：订阅从 `rss_subscriptions` 读写，文章在 feed fetch 后带完整
订阅上下文写入 `rss_articles`，后续 read/favorite/read-later 状态写布尔列。

## Hive Box 清单

### 全局 Box（不按语言分区）

| Box 名 | 内容 | Key 格式 |
|--------|------|----------|
| `settings` | 所有应用设置 | 字符串 key（`aiProviderId`, `themeMode`, `dictionarySources` 等） |
| `word_levels` | 单词等级映射 | 单词字符串 |
| `rss_subscriptions` | RSS 订阅 | Hive key（自动生成） |
| `book_glossary` | 作品词汇缓存 | `BookGlossaryEntry.id` |

### 按语言分区的 Box

模式：`{name}_{languageCode}`，当前 `languageCode = 'en'`

| Box 模式 | 内容 | 存储模型 |
|----------|------|----------|
| `books_{lang}` | 书籍元数据 | `BookMetadata` (0) |
| `user_vocabulary_{lang}` | 用户词汇状态 | `${lang}_${canonical}` → `UserVocabularyEntry` JSON |
| `word_bookmarks_{lang}` | 单词书签 | `BookmarkedWord` (1) |
| `reading_bookmarks_{lang}` | 阅读书签 | `ReadingBookmark` (2) |
| `reading_config_{lang}` | 旧版阅读器配置，作为 Drift 迁移来源保留 | `ReadingConfig` (3) |
| `reading_time_{lang}` | 阅读时长记录 | 结构化 key |
| `dictionary_cache_{lang}` | 词典缓存 | `{source}_{word}` → 缓存内容 |
| `word_contexts_{lang}` | 单词上下文 | 结构化 key |
| `learning_items_{lang}` | 学习条目 | `LearningItem` (11) |
| `learning_analytics_{lang}` | 学习分析 | 结构化 key |

### Bootstrap 流程

```dart
bootstrapStorage() {
  Hive.init(path);
  registerAdapters();          // 注册 8 个 HiveAdapter
  registerLanguageModules();   // EnglishLanguageModule → LanguageRegistry
  openBoxes();                 // settings + en-boxes × 10 + word_levels + rss_subscriptions + book_glossary
  runMigrations();             // v1 → v2 迁移
  bootstrapDatabase();         // HiveToDriftMigration（带完成标记）+ reading_config 启动快照
}
```

## Settings Box Key 汇总

| Key | 类型 | 默认值 |
|-----|------|--------|
| `aiProviderId` | String | `deepseek` |
| `aiApiKeys` | JSON map | `{}` |
| `aiBaseUrls` | JSON map | `{}` |
| `aiModels` | JSON map | `{}` |
| `themeMode` | int (0-2) | `0` (system) |
| `appThemeId` | String | `classic` |
| `dailyReadingGoalMinutes` | int | `60` |
| `unknownColor` | int (ARGB32) | `0xFFE74C3C` |
| `learningColor` | int (ARGB32) | `0xFF8E44AD` |
| `knownColor` | int (ARGB32) | `0xFF999999` |
| `backupEnabled` | bool | `false` |
| `includeSecretsInBackup` | bool | `false` |
| `backupFolderPath` | String | `''` |
| `backupFolderBookmark` | String | `''` |
| `backupIntervalMinutes` | int | `60` |
| `lastBackupAt` | String (ISO8601) | null |
| `lastBackupPath` | String | null |
| `lastSeenReleaseNotesVersion` | String | `''` |
| `active_source_language` | String | `'en'` |
| `target_explanation_language` | String | `'zh'` |
| `enabledExperimentalFeatures` | JSON array | `[]` |
| `forceDefaultBookCover` | bool | `false` |
| `city_atmosphere.enabled` | bool | `false` |
| `city_atmosphere.theme_mode` | String enum | `systemTime` |
| `city_atmosphere.manual_theme_id` | String | `cityDawn` |
| `city_atmosphere.blend_mode` | String enum | `followTheme` |
| `city_atmosphere.manual_scene` | String enum | `none` |
| `city_atmosphere.intensity` | double | `0.30` |
| `city_atmosphere.reduce_motion` | bool | `false` |
| `city_atmosphere.performance_mode` | String enum | `auto` |
| `dictionarySources` | JSON array | Collins/WordNet/dictAPI/Longman objects with `type`, `enabled`, `priority`, optional `supportedLanguages` |
| `aiChapterSummaryCount` | int | `0` |
| `aiTextAnalysisCount` | int | `0` |
| `aiPracticeCount` | int | `0` |
| `aiWordAnalysisCount` | int | `0` |

## 备份 Schema

备份文件为 `.zip`，内含：
- `data/app.json`：`boxes.*` 包含所有 box 数据
- `data/files/`：书籍文件副本

备份不包含：本地文件路径、macOS Bookmark、API keys（除非 `includeSecretsInBackup=true`）

## 新增 Hive 类型 Checklist

1. 在 `hive_type_ids.dart` 中分配新 ID（检查 reserved set）
2. 在模型中添加 `@HiveType(typeId: N)` 和 `@HiveField(n)`
3. 在 `hive_storage.dart:registerFlowReadHiveAdapters()` 中注册 Adapter
4. 在 `hive_storage.dart:openFlowReadHiveBoxes()` 中打开 box（如需新 box）
5. 在 `hive_box_names.dart` 中定义 box 名常量
6. 运行 `fvm dart run build_runner build --delete-conflicting-outputs`
7. 更新 `test/storage_contract_test.dart`：`expect(HiveTypeIds.reserved, hasLength(N))`
