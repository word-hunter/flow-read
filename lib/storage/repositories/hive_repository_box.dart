import 'package:hive/hive.dart';

import '../hive_box_names.dart';

Box<T> requireOpenHiveBox<T>(String name) {
  if (!Hive.isBoxOpen(name)) {
    throw StateError(
      'Hive box "$name" must be opened by bootstrapStorage() or the test '
      'storage helper before repository init.',
    );
  }
  return Hive.box<T>(name);
}

String activeHiveLanguageCode(String? override) {
  final explicit = override?.trim().toLowerCase();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  if (!Hive.isBoxOpen(HiveBoxNames.settings)) {
    return HiveBoxNames.defaultLanguageCode;
  }
  final stored = Hive.box(HiveBoxNames.settings).get(
    HiveBoxNames.activeSourceLanguageKey,
    defaultValue: HiveBoxNames.defaultLanguageCode,
  );
  final code = stored?.toString().trim().toLowerCase();
  return code == null || code.isEmpty ? HiveBoxNames.defaultLanguageCode : code;
}
