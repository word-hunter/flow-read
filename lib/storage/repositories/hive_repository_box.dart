import 'package:hive/hive.dart';

Box<T> requireOpenHiveBox<T>(String name) {
  if (!Hive.isBoxOpen(name)) {
    throw StateError(
      'Hive box "$name" must be opened by bootstrapStorage() or the test '
      'storage helper before repository init.',
    );
  }
  return Hive.box<T>(name);
}
