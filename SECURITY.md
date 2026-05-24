# Security Policy

## Supported Versions

Flow Read is currently in alpha. Security fixes are applied to the latest
published release and the default branch.

## Reporting A Vulnerability

If the report does not contain sensitive information, open a GitHub issue:

https://github.com/word-hunter/flow-read/issues/new

If the report includes secrets, private reading content, backup files, logs, or
exploit details that should not be public, do not post those details in a
public issue. Use GitHub private vulnerability reporting if it is enabled for
the repository, or open a minimal public issue asking for a private contact
path.

## Handling Secrets

- Do not commit API keys, `.env` files, backups, logs, private books, or local
  planning files.
- Internal planning notes belong under `private/`, which is ignored by Git.
- Run gitleaks before publishing release branches or tags.
- Backup files exclude AI secrets by default. Treat backups as sensitive if the
  user enabled secret export.

## Release Security Checklist

- Run static analysis and tests.
- Run gitleaks on Git history and tracked files.
- Verify macOS entitlements in the built app bundle, not only source files.
- Publish checksums for downloadable artifacts.
- Clearly state whether a macOS build is signed and notarized.
