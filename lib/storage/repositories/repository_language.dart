import '../hive_box_names.dart';

String normalizeRepositoryLanguageCode(String? languageCode) {
  final normalized = languageCode?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return HiveBoxNames.defaultLanguageCode;
  }
  return normalized;
}
