import '../legacy_backup_box_names.dart';

String normalizeRepositoryLanguageCode(String? languageCode) {
  final normalized = languageCode?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return LegacyBackupBoxNames.defaultLanguageCode;
  }
  return normalized;
}
