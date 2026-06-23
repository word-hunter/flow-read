# Reading Memory Regression Matrix

> @source private/doc/底层-知识库-待完成任务.md test/services/review_candidate_service_test.dart test/practice_screen_test.dart test/widgets/ai_assistant_panel_test.dart test/rss_provider_test.dart test/services/reading_memory_overlay_service_test.dart test/reader_text_view_test.dart test/reader_page_workspace_lookup_test.dart test/services/reading_memory/chapter_summary_source_scope_cache_test.dart test/services/reading_memory_service_test.dart test/services/context_retrieval_service_test.dart test/services/reading_memory/book_insight_source_scope_service_test.dart

Last updated: 2026-06-23

This matrix keeps the long-term Reading Memory / Knowledge Layer regression gates discoverable after the feature slices are split across service, provider, and widget tests.

## Required Gates

| Closed loop | Regression gate | Test owner |
|-------------|-----------------|------------|
| Review candidate promotion | `candidate -> LearningItem -> converted`, including duplicate accept protection | `test/services/review_candidate_service_test.dart`, `test/practice_screen_test.dart` |
| Browser assistant memory write | Internal browser AI save uses `SourceKind.browser` and the browser source id | `test/widgets/ai_assistant_panel_test.dart` |
| RSS source lifecycle | Removing a subscription tombstones RSS sources, clears source cache, and keeps learning events according to retention policy | `test/rss_provider_test.dart` |
| Reading Memory Overlay | Empty overlay is a no-op, markers keep lookup taps, and reader page lookup still works with overlay enabled | `test/services/reading_memory_overlay_service_test.dart`, `test/reader_text_view_test.dart`, `test/reader_page_workspace_lookup_test.dart` |
| Source scope cache | Chapter summary cache writes, reads, and clears real `source_scope_cache` records through source lifecycle | `test/services/reading_memory/chapter_summary_source_scope_cache_test.dart` |
| Strict privacy | Metadata-only evidence keeps `shortExcerpt` empty and redacts lookup event source snippets | `test/services/reading_memory_service_test.dart` |
| Book Insight spoiler boundary | Book source projection and AI context exclude future summaries, characters, and terms past the spoiler boundary | `test/services/context_retrieval_service_test.dart`, `test/services/reading_memory/book_insight_source_scope_service_test.dart` |

## Stage Exit Check

Run this focused matrix when changing Reading Memory, Reader overlay, RSS/Browser source lifecycle, strict privacy, or Book Insight:

```bash
fvm flutter test test/services/review_candidate_service_test.dart test/practice_screen_test.dart test/widgets/ai_assistant_panel_test.dart test/rss_provider_test.dart test/services/reading_memory_overlay_service_test.dart test/reader_text_view_test.dart test/reader_page_workspace_lookup_test.dart test/services/reading_memory/chapter_summary_source_scope_cache_test.dart test/services/reading_memory_service_test.dart test/services/context_retrieval_service_test.dart test/services/reading_memory/book_insight_source_scope_service_test.dart
fvm dart analyze
dart run tool/verify_docs.dart
git diff --check
```
