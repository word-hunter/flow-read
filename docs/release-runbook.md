# Release Runbook

This runbook describes the public release flow for Flow Read.

## Release Policy

- Do not bump the app version as part of ordinary feature work.
- Only change `pubspec.yaml`, `lib/services/app_version.dart`, and
  `CHANGELOG.md` when explicitly preparing a release.
- Keep prerelease tags such as `v0.0.3-alpha` while the app is in alpha.
- For the first stable release, choose a non-prerelease version and update all
  version surfaces in one release commit.

## Preflight

1. Start from a clean checkout.
2. Confirm internal planning notes are under `private/` and not tracked.
3. Confirm `LICENSE`, `NOTICE`, `PRIVACY.md`, `SECURITY.md`, and README are up
   to date.
4. Confirm bundled asset and data licenses are recorded in `NOTICE`.
5. Run a secret scan against Git history and tracked files.
6. Decide whether the macOS artifact is signed and notarized. If it is not,
   state that in the release notes.

## Version Update

Only run this step when preparing the release:

```bash
dart run tool/release.dart current
dart run tool/release.dart bump patch
```

Use `minor` or `major` instead of `patch` when the release semantics require
it. For prereleases, keep using the current prerelease channel until the stable
release is explicitly chosen.

After bumping, inspect:

- `pubspec.yaml`
- `lib/services/app_version.dart`
- `CHANGELOG.md`

Polish generated changelog notes into user-facing release notes before tagging.

## Local Verification

Run:

```bash
fvm flutter pub get
fvm dart analyze
fvm flutter test
git diff --check
dart run tool/release.dart check
dart run tool/release.dart package-local
```

If FVM is unavailable, use the matching local Flutter SDK.

The local package command verifies both macOS bundle metadata and Flutter
runtime version markers, then creates a zip under `dist/`.

Before manually launching the app, quit any already running Flow Read process,
especially local Debug builds. Debug/Profile builds use a separate bundle
identifier, but an old process can still make visual verification misleading.
Confirm the built app displays the expected version in both the About surface
and Settings.

## macOS Entitlements

Verify entitlements from the built bundle:

```bash
codesign -d --entitlements :- build/macos/Build/Products/Release/FlowRead.app
```

Confirm at least:

- `com.apple.security.app-sandbox`
- `com.apple.security.network.client`
- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.files.bookmarks.app-scope`

## Tag And Publish

After committing the release metadata:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

For alpha releases, use the prerelease tag form, for example:

```bash
git tag v0.0.3-alpha
git push origin v0.0.3-alpha
```

GitHub Actions builds the macOS artifact, validates release metadata, verifies
the built app bundle and runtime version markers, exports release notes, and
creates the GitHub Release.

## Post-Publish Verification

1. Confirm the GitHub Actions release workflow completed.
2. Confirm the GitHub Release has the expected tag, title, notes, prerelease
   flag, and macOS zip asset.
3. Download the asset and verify it extracts.
4. Record the SHA-256 digest in the release notes or release metadata.
5. Quit any local Debug/Profile Flow Read instance.
6. Launch the built app and verify About/Settings show the released version.

## Rollback

If the release artifact is bad:

1. Mark the GitHub Release as draft or delete it.
2. Delete the bad tag locally and remotely only after confirming no users should
   consume it.
3. Fix the issue on a new commit.
4. Publish a new patch release or replacement prerelease tag.
