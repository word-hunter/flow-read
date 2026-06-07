# AGENTS.md

## Scope

These instructions apply to the entire `flow_read` repository.

## Project Context

Flow Read is a Flutter desktop/mobile app for English reading and vocabulary learning. It combines EPUB reading, word lookup, AI assistance, RSS reading, vocabulary review, backup/import, release tooling, and macOS-specific behavior.

Core stack:

- Flutter / Dart, locked by `.fvmrc`.
- Provider for app state.
- Hive / hive_flutter for persistence.
- `epubx`, `html`, `xml`, `http`, and `file_picker` for content and import flows.
- Material Design 3 for UI.

Prefer the existing project structure:

- `lib/main.dart`: app entry, providers, routes, global shortcuts.
- `lib/app/`: app-level provider setup.
- `lib/models/`: data models and Hive types.
- `lib/providers/`: `ChangeNotifier` state.
- `lib/services/`: persistence, parsing, AI, backup, RSS, lookup, release/app services.
- `lib/pages/`: reader sub-pages, including the active desktop reader flow.
- `lib/screens/`: app-level screens.
- `lib/widgets/`: reusable UI components.
- `lib/theme/`: theme constants and app styling.
- `lib/storage/`: Hive box names, type ids, migrations.
- `test/`: focused unit/widget tests.

## Collaboration Defaults

- Reply in Chinese unless the user asks otherwise.
- When the user asks for a plan, investigation, or documentation only, do not change code.
- When the user reports a concrete bug, treat it as a request to fix the behavior end to end.
- Start from the exact file, screenshot, route, error, or symptom the user provides.
- Read the active code path before editing. In reader work, confirm whether the target is `lib/pages/reader_page.dart` rather than older or alternate reader surfaces.
- Keep changes narrow and consistent with existing service/provider/widget boundaries.
- Do not revert user changes or unrelated local modifications.
- Do not bump app versions unless the user explicitly asks for a release/version update.

## Commands

Prefer FVM when available because the project pins Flutter in `.fvmrc`:

```bash
fvm flutter pub get
fvm dart analyze
fvm flutter test
```

If FVM is not available in the environment, use the matching local Flutter SDK:

```bash
flutter pub get
dart analyze
flutter test
```

For narrow changes, prefer targeted verification:

```bash
fvm flutter test test/<focused_test>.dart
fvm dart analyze
git diff --check
```

Release tooling:

```bash
dart run tool/release.dart current
dart run tool/release.dart check
dart run tool/release.dart package-local
dart run tool/release.dart package-local --skip-tests
```

Only run version bump commands when explicitly requested:

```bash
dart run tool/release.dart bump patch
```

## Implementation Guidelines

- Prefer existing services and providers over new parallel code paths.
- Keep derived UI state render-time or source-backed when possible; avoid effect-style synchronization unless there is no cleaner option.
- Keep long-running work off the UI thread. Backup/export/import and parsing paths must not block visible interaction.
- When calling multiple independent async operations, prefer `Future.wait` over serial `await` chains. For example, `await Future.wait([a.init(), b.init()])` instead of `await a.init(); await b.init();`.
- Do not micro-optimize existing serial init chains that already work — refactor only when adding new calls or when the author explicitly asks.
- Use structured parsers for EPUB, RSS, HTML, JSON, and Hive-backed data instead of ad hoc string manipulation.
- Preserve existing persisted schemas and storage contracts. When changing Hive models, update type ids/migrations deliberately and add tests.
- Avoid broad refactors during bug fixes unless the existing path is clearly the root cause.
- Add comments only for non-obvious logic, especially persistence, macOS entitlement, async, or parser edge cases.

## Feature-Specific Expectations

### Reader

- The reader should keep word tap/lookup behavior working when rendering structure, images, highlights, or search state.
- Opening a new chapter/page should reset stale scroll position instead of preserving old offsets.
- Search should remain modal/non-disruptive, cap initial results, support "show more", and keep body highlighting only while the search UI is open.
- Selected-text analysis should reuse the canonical analysis/bottom-sheet flow rather than creating duplicate surfaces.

### Dictionary and Vocabulary

- Prefer the dedicated dictionary services under `lib/services/dictionary/` when present.
- Keep dictionary detail rendering shared across reader and vocabulary surfaces.
- Preserve source ordering and settings-backed source controls.
- Imported examples should surface through the existing word context/example UI rather than a separate display path.

### AI

- AI integrations should use the provider/config abstraction, not a single hard-coded provider.
- AI controls should remain visible in Settings when they are user-facing.
- Use one shared availability predicate for AI entry points when possible.
- Cache and failure states should be visible enough for users to understand what happened.

### Settings

- Keep Settings grouped by feature area such as appearance, AI, backup, experimental features, and release notes.
- Do not flatten settings into an undifferentiated list.
- Experimental features should be exposed through a settings entry or panel, not hidden constants.
- RSS should remain opt-in / feature-gated unless the user explicitly changes that product decision.

### Backup and Import

- Backup is opt-in by default.
- Folder selection, scheduled sync, and immediate backup must work through the existing backup/import pipeline.
- Imports are not complete until dependent services are reinitialized and visible app state reflects restored data.
- Preserve Flow Read data when adding sibling import formats such as Word Hunter.
- For Word Hunter imports, preserve source schema semantics exactly: `known` maps to mastered, `context` maps to learning/examples, and known wins on conflicts.
- Validate import fixes through the real file-entry path when practical, not only parser helpers.

### RSS

- RSS work should cover subscription CRUD, latest-content rendering, reading-side polish, and highlighted-word lookup reuse.
- Silent no-op behavior is a bug. Surface loading, empty, and error states in the UI.
- On macOS network failures, check the signed app bundle entitlements, not just source entitlement files.

### macOS

- For file/folder access, remember that a stored path is not durable authorization. Security-scoped bookmarks may be required.
- For network access and backup access, verify the built app bundle entitlements when the source file and runtime behavior disagree:

```bash
codesign -d --entitlements :- build/macos/Build/Products/Debug/flow_read.app
```

- The native Preferences menu is wired through `macos/Runner/Base.lproj/MainMenu.xib`, `macos/Runner/AppDelegate.swift`, and the `flow_read/app_menu` channel.

## Frontend Guidance

Build with the existing app design instead of introducing a marketing-style experience.

- This is a reading and learning tool. UI should feel quiet, focused, and efficient.
- Use Material 3 conventions and existing project widgets before inventing new controls.
- Use icons for common tool actions, switches for binary settings, sliders/steppers/inputs for numeric settings, segmented controls or tabs for modes, and menus for option sets.
- Do not add a landing page when the request is for an app feature. Build the usable workflow as the first screen.
- Do not put cards inside cards. Use cards for repeated items, modals, or framed tools only.
- Keep page sections unframed or full-width within the app layout.
- Avoid decorative gradient blobs, bokeh, or unrelated visual ornaments.
- Avoid one-note palettes. Respect the existing theme and do not make a feature read as dominated by one hue family.
- Make text fit on mobile and desktop. Buttons, cards, sidebars, sheets, and dialogs must not overlap or clip labels.
- Use stable dimensions for fixed-format UI such as toolbars, counters, tabs, reader controls, and list rows so hover/selection/loading states do not shift layout.
- Do not scale font size with viewport width. Keep letter spacing at normal unless an existing style requires otherwise.
- Match text scale to the surface. Use compact headings in panels, cards, sidebars, dialogs, and settings sections.
- Build complete states: loading, empty, error, disabled, selected, saving, and success states where the workflow needs them.
- Do not use visible in-app text to explain implementation details, keyboard shortcuts, or how a visual element was built.

## Documentation Freshness

`docs/` contains architecture reference docs used as context for code generation. These docs describe **current** code structure. Stale docs produce incorrect code.

### Before trusting any `docs/*.md` claim

1. **Find the `@source` annotation** at the top of the doc or section. It points to the canonical code location.
2. **If the doc says "class X has fields A, B, C"** but your code change added field D, update the doc.
3. **If a file path in a doc returns 404**, the doc is stale — flag it, don't trust adjacent claims.
4. **If a Hive type ID, box name, or key constant in a doc differs from the actual source** (`lib/storage/hive_type_ids.dart`, `lib/storage/hive_box_names.dart`), prefer the source file.

### Doc writing rules

- Every `docs/*.md` doc must have a `@source` line linking to the primary file(s) it documents.
- When adding/removing a Hive type, service class, provider field, or route — check `docs/` for impacted files.
- Docs describe **what is**, not what will be. Plans go in `private/`.
- Run `dart run tool/verify_docs.dart` after structural changes to catch stale references.

### verify_docs.dart checks

```bash
dart run tool/verify_docs.dart
```

Validates:
- All `@source` file paths in docs exist in the repo
- Hive type IDs in `docs/data-model.md` match `lib/storage/hive_type_ids.dart`
- Box names in `docs/storage-contract.md` match `lib/storage/hive_box_names.dart`
- Key service classes referenced in docs exist in `lib/services/`

This is NOT a CI gate — it's a quick sanity check before trusting docs for code generation.

### When generating code from docs

1. Run `dart run tool/verify_docs.dart` first
2. For any claim you intend to act on, read the `@source` file to confirm
3. If docs and code disagree, **trust the code** and flag the stale doc
4. After making a structural change (new Hive type, new box, renamed class), update the relevant doc

## Git Commit Discipline

- **Always run `git status` before committing** to verify only intended files are staged.
- Never use `git add .` or `git add -A`; prefer `git add <specific-file>` to avoid accidentally staging gitignored or unrelated files.
- Respect `.gitignore`. If a gitignored file appears in the staging area, use `git reset HEAD <file>` to unstage it before committing.
- Only commit when the user explicitly requests it.

## Verification Expectations

- Choose tests based on risk and touched code. A narrow parser or service change should get a focused unit test; shared UI or state changes should get widget/provider coverage.
- Existing useful targeted tests include reader, RSS, settings, backup, dictionary, EPUB, search, selected text, and storage contract tests under `test/`.
- For UI work, use widget tests when practical. If running the app is necessary, start the dev target and report the URL/window target or command used.
- Always run `git diff --check` before finishing after file edits.
- If a check cannot be run in the current environment, state that clearly in the final response.
