import 'dart:async';

import 'package:drift/drift.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tests create independent in-memory databases across files.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
