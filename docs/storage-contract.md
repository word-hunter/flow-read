# Flow Read Storage Contract

> @source lib/storage/legacy_backup_box_names.dart lib/storage/storage_bootstrap.dart lib/storage/database/app_database.dart lib/storage/database/bootstrap.dart lib/storage/database/tables.dart lib/services/backup_service.dart lib/services/settings_service.dart

Last updated: 2026-06-15

## Runtime Schema

Flow Read runtime storage is Drift-only.

- Database file: `flow_read.db`
- Current Drift schema version: `2`
- Startup entrypoint: `bootstrapStorage()`
- Runtime source of truth: Drift DAOs and repository interfaces
- Legacy backup compatibility: `.flow.bak` still serializes data under `boxes` keys defined by `LegacyBackupBoxNames`

`bootstrapStorage()` registers language modules, then delegates database setup to
`bootstrapDatabaseStorage()`. The database bootstrap creates `AppDatabase`, reads
the active source language from the Drift `settings` table, and publishes Drift
repositories/snapshot providers for the app.

## Drift Tables

| Table | DAO | Purpose |
|----|-----|------|
| `books` | BookDao | Book metadata and reading progress |
| `user_vocabulary` | UserVocabularyDao | Known/learning vocabulary by language |
| `word_bookmarks` | BookmarkDao | Word bookmarks |
| `reading_bookmarks` | BookmarkDao | Reading bookmarks |
| `reading_config` | ReadingConfigDao | Reader display settings |
| `reading_time` | ReadingTimeDao | Reading duration counters |
| `dictionary_cache` | DictionaryCacheDao | Regenerable dictionary cache |
| `word_contexts` | WordContextDao | Example sentences and context |
| `learning_items` | LearningItemDao | Review/practice items |
| `learning_analytics` | LearningAnalyticsDao | Learning counters |
| `word_levels` | WordLevelDao | Built-in word level index |
| `rss_subscriptions` | RssDao | RSS subscriptions |
| `rss_articles` | RssDao | RSS article cache and read/favorite/read-later flags |
| `book_glossary` | BookGlossaryDao | Per-book glossary entries |
| `character_registry` | CharacterRegistryDao | Character registry payloads |
| `source_records` | ReadingMemoryDao | Book/RSS/browser/manual source scope records and tombstones |
| `knowledge_entities` | ReadingMemoryDao | Long-term word/phrase/pattern/book-term memory identities |
| `knowledge_explanations` | ReadingMemoryDao | Saved user/AI/dictionary/generated explanations |
| `knowledge_evidences` | ReadingMemoryDao | Short citations connecting entities to source context |
| `memory_events` | ReadingMemoryDao | Lookup, AI, vocabulary, review, and bookmark learning signals |
| `source_scope_cache` | ReadingMemoryDao | Deletable source-scoped cache payloads |
| `review_candidates` | ReadingMemoryDao | Memory-derived candidates for future review conversion |
| `settings` | SettingsDao | App settings |

## Legacy Backup Keys

The names below are compatibility keys inside backup payloads, not runtime
storage handles. They remain stable so older `.flow.bak` files can be imported
and newly exported backups keep the same data shape.

### Global Keys

| Key | Content |
|----|------|
| `settings` | Exportable app settings |
| `rss_subscriptions` | RSS subscription list |
| `book_glossary` | Book glossary entries |
| `character_registry` | Character registry payloads |
| `word_levels` | Legacy/regenerable word level key, excluded from backup export |

### Language-Scoped Keys

Pattern: `{name}_{languageCode}`. The default language is `en`.

| Key Pattern | Content |
|----------|------|
| `books_{lang}` | Book metadata |
| `user_vocabulary_{lang}` | Vocabulary status |
| `word_bookmarks_{lang}` | Word bookmarks grouped by book |
| `reading_bookmarks_{lang}` | Reading bookmarks grouped by book |
| `reading_config_{lang}` | Reader display settings |
| `reading_time_{lang}` | Reading duration counters |
| `dictionary_cache_{lang}` | Regenerable dictionary cache, excluded from backup export |
| `word_contexts_{lang}` | Word context examples |
| `learning_items_{lang}` | Learning items |
| `learning_analytics_{lang}` | Learning counters |

## Startup Flow

```dart
bootstrapStorage()
  -> registerFlowReadLanguageModules()
  -> bootstrapDatabaseStorage()
       -> AppDatabase.create()
       -> settingsDao.valueFor('active_source_language')
       -> register Drift-backed runtime snapshots
```

## Settings Keys

| Key | Type | Default |
|-----|------|--------|
| `aiProviderId` | String | `deepseek` |
| `aiApiKeys` | JSON map | `{}` |
| `aiBaseUrls` | JSON map | `{}` |
| `aiModels` | JSON map | `{}` |
| `themeMode` | int (0-2) | `0` (system) |
| `appThemeId` | String | `classic` |
| `dailyReadingGoalMinutes` | int | `60` |
| `openTocOnBookOpen` | bool | `true` |
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
| `active_source_language` | String | `en` |
| `target_explanation_language` | String | `zh` |
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
| `dictionarySources` | JSON array | Dictionary source settings |
| `aiChapterSummaryCount` | int | `0` |
| `aiTextAnalysisCount` | int | `0` |
| `aiPracticeCount` | int | `0` |
| `aiWordAnalysisCount` | int | `0` |

## Backup Schema

Backup files use the `.flow.bak` zip format:

- `manifest.json`: format metadata and book file index
- `data/app.json`: `boxes.*` payload using `LegacyBackupBoxNames`
- `books/*.epub` and optional covers: source assets

`BackupService` exports from Drift DAOs and restores imports into Drift tables.
Local-only settings such as folder paths, bookmarks, last backup timestamps, and
secrets are excluded unless the relevant user setting explicitly includes
secrets.

## Storage Change Checklist

1. Add or update the Drift table/DAO/repository.
2. Keep provider bootstrap snapshots in `lib/storage/database/bootstrap.dart` aligned with runtime providers.
3. If backup/import shape changes, update `LegacyBackupBoxNames`, `BackupService`, and backup tests.
4. Update this document and `docs/data-model.md`.
5. Run `fvm dart run tool/verify_docs.dart`, focused storage tests, and `git diff --check`.
