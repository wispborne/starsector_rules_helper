import 'dart:io';

Stream<int> pollFileForModification(File file, int interval) async* {
  var lastModified = file.lastModifiedSync();

  while (true) {
    await Future.delayed(Duration(seconds: interval));
    final newModified = file.lastModifiedSync();

    if (newModified.isAfter(lastModified)) {
      lastModified = newModified;
      yield 1;
    }
  }
}
