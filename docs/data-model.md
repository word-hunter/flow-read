# Flow Read Data Model

> @source lib/models/ lib/storage/database/tables.dart packages/flow_ai/lib/src/models/ packages/flow_dictionary/lib/src/ packages/flow_rss/lib/src/rss_models.dart

Last updated: 2026-06-21

## Runtime Persistence

Flow Read model classes are plain Dart/domain objects. Runtime persistence is
handled by Drift tables, DAOs, and repository adapters under `lib/storage/`.
Generated model adapters are no longer part of the runtime model contract.

| Domain Area | Drift Table | Primary Model / Value Object |
|------|------|------|
| Books | `books` | `BookMetadata`, `BookDifficultyRating` |
| Vocabulary | `user_vocabulary` | `UserWordStatus`, `UserVocabularyKey` |
| Word bookmarks | `word_bookmarks` | `BookmarkedWord` |
| Reading bookmarks | `reading_bookmarks` | `ReadingBookmark` |
| Reader settings | `reading_config` | `ReadingConfig` |
| Reading time | `reading_time` | `ReadingTimeService` values |
| Dictionary cache | `dictionary_cache` | source/word cache payloads |
| Word context | `word_contexts` | `WordContextExample` |
| Learning items | `learning_items` | `LearningItem` |
| Learning analytics | `learning_analytics` | counter values |
| Word levels | `word_levels` | `WordLevelInfo`, `LevelKey` |
| RSS | `rss_subscriptions`, `rss_articles` | `RssFeedSubscription`, `RssArticle` |
| Book glossary | `book_glossary` | `BookGlossaryEntry` |
| Characters | `character_registry` | `CharacterRegistryEntry` |
| Reading memory sources | `source_records` | `MemorySourceRecord` |
| Reading memory entities | `knowledge_entities` | `MemoryKnowledgeEntity` |
| Reading memory explanations | `knowledge_explanations` | `MemoryKnowledgeExplanation` |
| Reading memory evidences | `knowledge_evidences` | `MemoryKnowledgeEvidence` |
| Reading memory events | `memory_events` | `MemoryEvent` |
| Source scope cache | `source_scope_cache` | `SourceScopeCacheEntry` |
| Review candidates | `review_candidates` | `ReviewCandidate` |
| Settings | `settings` | `SettingsService` values |

## Reader Models

| Model | File | Purpose |
|------|------|------|
| `Book` | `book.dart` | In-memory book with chapters, cover, and language metadata |
| `Chapter` | `chapter.dart` | Chapter content, plain text, and render blocks |
| `ContentBlock` | `content_block.dart` | EPUB render block: text, heading, image, divider, or list item |
| `ReadingToken` | `reading_token.dart` | Token surface/canonical/language/offset metadata |
| `TokenizedText` | `reading_token.dart` | Token stream used by reader rendering and lookup |
| `AggregatedVocabulary` | `aggregated_vocabulary.dart` | Cross-chapter vocabulary view |
| `BookDifficulty` | `book_difficulty.dart` | L1-L5 difficulty score and breakdown |

## Learning Models

| Model | Purpose |
|------|------|
| `UserWordStatus` | Known/learning vocabulary status |
| `UserVocabularyKey` | Language-aware storage key for canonical vocabulary |
| `UserVocabularyEntry` | Vocabulary entry with status, timestamps, and source metadata |
| `WordLevelInfo` | Built-in word-level index row |
| `LearningItem` | Review/practice item with scheduling metadata |
| `LearningReviewResult` | Review feedback state: new item, forgotten, vague, remembered, mastered, and legacy missed |
| `WordContextExample` | Imported or captured sentence context |
| `BookGlossaryEntry` | Per-book glossary explanation and access timestamps |
| `MemorySourceRecord` | Book/RSS/browser/manual source scope metadata and tombstone state |
| `MemoryKnowledgeEntity` | Long-term word/phrase/pattern/book-term memory identity |
| `MemoryKnowledgeExplanation` | User/AI/dictionary/generated explanation attached to an entity |
| `MemoryKnowledgeEvidence` | Short source citation connecting an entity to reading context |
| `MemoryEvent` | Lookup, AI, vocabulary, review, and bookmark learning signal |
| `ReviewCandidate` | Memory-derived candidate that can be accepted and converted into a deduplicated `LearningItem` |

## AI Models

| Model | Purpose |
|------|------|
| `AISummary` | Chapter summary with events, characters, vocabulary, and takeaways |
| `AIChapterPreview` | Pre-reading preview |
| `AITextAnalysis` | Selected text analysis |
| `AIPracticeSet` / `PracticeQuestion` | AI-generated exercises |
| `WordAnalysis` | AI vocabulary explanation |
| `ChapterAIStatus` | Chapter AI state machine |
| `ChapterAISummaryCoverage` | Generated chapter coverage |
| `AIContextSnapshot` | Shared assistant context snapshot |
| `AIAssistantActionType` | Assistant action enum |
| `AIActionResult` | Assistant action result |
| `AIAssistantSession` | Lightweight assistant session |
| `AIChatMessage` | Assistant chat message |
| `AIAssistantCitation` | Answer citation anchor |
| `AIAutomationSettings` | Automation settings |
| `ReadingInsightProfile` | Runtime reading profile |
| `CharacterRegistryEntry` | Character registry item |

## Dictionary Models

| Model | Package | Purpose |
|------|---------|------|
| `VisualDefinition` | `flow_dictionary` | Wikidata 可视化释义结果（图片 URL、标签、描述、置信度） |
| `DictionarySourceConfig` | `flow_dictionary` | 词典来源配置（启用、优先级、支持语言） |
| `CompoundAnalysis` | `flow_dictionary` | 复合词拆分结果 |

## Language Module Models

| Interface | Implementation |
|------|------|
| `Tokenizer` | `EnglishLanguageModule` |
| `SentenceSplitter` | `EnglishLanguageModule` |
| `SyntaxMarkerProvider` | `EnglishLanguageModule` |
| `LanguageModule` | `EnglishLanguageModule` |

`LanguageRegistry` stores modules by `languageCode` and is registered during
`bootstrapStorage()`.

## Model Change Checklist

1. Keep domain classes free of persistence annotations.
2. Add or update the matching Drift table, DAO, and repository adapter when persistence changes.
3. Update backup/import mapping if the persisted payload participates in `.flow.bak`.
4. Update this document and `docs/storage-contract.md`.
5. Add focused repository/service tests for the changed behavior.
