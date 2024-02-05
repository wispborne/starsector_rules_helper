import 'dart:async';
import 'dart:io';

var fileChanges = StreamController();

/// Should probably be a way to stop this.
pollFileForModification(File file, int interval) async {
  var lastModified = file.lastModifiedSync();
  final fileChangesInstance = fileChanges;

  while (!fileChangesInstance.isClosed) {
    await Future.delayed(Duration(seconds: interval));
    final newModified = file.lastModifiedSync();

    if (newModified.isAfter(lastModified)) {
      lastModified = newModified;
      fileChanges.add(file);
    }
  }
}
