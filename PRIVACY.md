# Privacy

Flow Read is local-first. The app does not require an account and does not send
reading data to a Flow Read server.

## Local Data

Flow Read stores books, reading progress, vocabulary state, learning items,
RSS subscriptions, settings, dictionary cache, AI cache, and backup metadata on
the local device using Hive and platform application-support directories.

Imported books and backups remain on the device unless the user explicitly
chooses a folder, opens a file, exports a backup, or sends text to a configured
external service.

## AI Requests

AI features are opt-in and require the user to configure an API provider and
API key. When the user runs an AI action, the app may send selected text,
nearby context, chapter text, vocabulary, practice prompts, or word context to
the configured provider endpoint.

Flow Read does not operate that provider. The provider's privacy policy and
terms apply to those requests.

## Online Dictionary Requests

The app includes local dictionary fallback data. If online dictionary sources
are enabled, Flow Read may request dictionary entries from external services or
websites such as dictionaryapi.dev, Collins, or Longman. These requests can
reveal the looked-up word and network metadata to those services.

Online dictionary sources can be disabled where the settings UI exposes that
control. A stable release must keep a local fallback path available.

## RSS And Web Content

When RSS or browser-style reading features are used, Flow Read requests the
URLs provided by the user. Feed providers and websites can observe normal
network metadata for those requests.

## Backups

Backups are opt-in. Backup files are written to a folder chosen by the user.
By default, API keys and provider secrets are excluded from backups. If the
user enables secret export, backup files can contain those secrets and should
be stored carefully.

Restoring a backup imports Flow Read data into the local app store. Device-
local backup folder paths, security-scoped bookmarks, and last-backup metadata
are intentionally not overwritten by imported backups.

## Logs

Flow Read writes local diagnostic logs for app events and failures. Logs are
structured JSONL files stored under the app support directory and are retained
for a limited period by the app logger. Log entries are designed to redact
secrets, selected text, book titles, local paths, URL query strings, and error
messages.

Do not share logs publicly without reviewing them first.

## Data Removal

Users can remove local app data by deleting Flow Read's application-support
data through the operating system. Backup files live wherever the user chose to
write them and must be deleted separately.

## Contact

For privacy issues, use the GitHub repository issue tracker unless the report
contains sensitive information. Do not include API keys, private books, backup
files, or log files in public issues.
