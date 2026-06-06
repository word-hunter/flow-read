# Flow Read Storage Contract

> @source lib/storage/hive_box_names.dart lib/storage/hive_type_ids.dart lib/storage/storage_migrations.dart

Last updated: 2026-06-06

## Schema 版本

**当前版本：2**

- v1 → v2：旧裸名 box → 语言后缀 box（`books` → `books_en`），`activeSourceLanguage = 'en'`
- 迁移逻辑：`storage_migrations.dart:runStorageMigrations()`，在 `bootstrapStorage()` 中调用

## Hive Box 清单

### 全局 Box（不按语言分区）

| Box 名 | 内容 | Key 格式 |
|--------|------|----------|
| `settings` | 所有应用设置 | 字符串 key（`aiProviderId`, `themeMode`, `dictionarySources` 等） |
| `word_levels` | 单词等级映射 | 单词字符串 |
| `rss_subscriptions` | RSS 订阅 | Hive key（自动生成） |

### 按语言分区的 Box

模式：`{name}_{languageCode}`，当前 `languageCode = 'en'`

| Box 模式 | 内容 | 存储模型 |
|----------|------|----------|
| `books_{lang}` | 书籍元数据 | `BookMetadata` (0) |
| `user_vocabulary_{lang}` | 用户词汇状态 | `${lang}_${canonical}` → `UserVocabularyEntry` JSON |
| `word_bookmarks_{lang}` | 单词书签 | `BookmarkedWord` (1) |
| `reading_bookmarks_{lang}` | 阅读书签 | `ReadingBookmark` (2) |
| `reading_config_{lang}` | 阅读器配置 | `ReadingConfig` (3) |
| `reading_time_{lang}` | 阅读时长记录 | 结构化 key |
| `dictionary_cache_{lang}` | 词典缓存 | `{source}_{word}` → 缓存内容 |
| `word_contexts_{lang}` | 单词上下文 | 结构化 key |
| `learning_items_{lang}` | 学习条目 | `LearningItem` (11) |
| `learning_analytics_{lang}` | 学习分析 | 结构化 key |

### Bootstrap 流程

```dart
bootstrapStorage() {
  Hive.init(path);
  registerAdapters();          // 注册 7 个 HiveAdapter
  registerLanguageModules();   // EnglishLanguageModule → LanguageRegistry
  openBoxes();                 // settings + en-boxes × 10 + word_levels + rss_subscriptions
  runMigrations();             // v1 → v2 迁移
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
