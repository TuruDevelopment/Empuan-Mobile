import 'dart:async';
import 'dart:io';

import 'package:Empuan/data/contacts_repository.dart';
import 'package:Empuan/data/offline.dart';

/// Runs before every test file. The secure storage and file plugins don't
/// exist in tests, so saved contacts live in memory and the offline cache in
/// a temporary folder, emptied for each file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ContactsVault.memory = {};
  OfflineImages.enabled = false;
  final dir = Directory.systemTemp.createTempSync('empuan_offline_test');
  OfflineCache.directoryOverride = dir;
  try {
    await testMain();
  } finally {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
