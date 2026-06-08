# Contributing

Thanks for working on Flow Read.

## Issue-Only Policy

This project currently accepts contributions through GitHub Issues only. Pull
requests are disabled and are not accepted.

Use issues to report bugs, request features, propose changes, or share
implementation notes. Please include enough context for maintainers to reproduce
or evaluate the request.

## Setup

Flow Read is a Flutter app pinned by `.fvmrc`. Prefer FVM:

```bash
fvm flutter pub get
make run
```

If FVM is unavailable, use a local Flutter SDK that matches `.fvmrc`.
The `make run` target reads local `.env` only for `FLOW_V2` and injects it via
`--dart-define`; `.env` stays ignored and must not be added as a Flutter asset.

## Checks

Use focused checks while developing, then run broader checks before sharing
local implementation notes in an issue:

```bash
fvm dart analyze
fvm flutter test
git diff --check
```

For release work, use the release tool:

```bash
dart run tool/release.dart current
dart run tool/release.dart check
dart run tool/release.dart package-local
```

Do not bump versions unless the change is explicitly a release/version update.

## Private Notes And Secrets

- Keep internal planning documents under `private/`.
- `private/` is ignored by Git and should not be force-added.
- Do not commit API keys, logs, backup files, imported books, or `.env` files.
- Run gitleaks before publishing public branches or release tags.

## Development Guidelines

- Keep changes scoped to the active feature or bug.
- Preserve the local-first data model.
- Preserve Hive schema and migration compatibility.
- Keep AI provider configuration user-controlled.
- Keep online dictionary sources optional with local fallback.
- Prefer focused tests for parser, storage, settings, backup, dictionary, RSS,
  reader, and release behavior.
