import 'dart:io';

import 'package:flyde/core/fs/wrapper/source_file.dart';
import 'package:flyde/features/build_server/cache/state/source_file_state.dart';
import 'package:test/test.dart';

void main() {
  test('Can be converted back to SourceFile', () async {
    final ogSourceFile = SourceFile.fromFile(
      1,
      File('./example/src/main.cpp'),
      entryDirectory: Directory('./example'),
    );
    final state = SourceFileState(
      id: ogSourceFile.id,
      hash: await ogSourceFile.hash,
      path: './example/src/main.cpp',
    );
    final sourceFile = await state.toSourceFile(Directory('./example'), entry: ogSourceFile.entry);

    expect(sourceFile.id, equals(ogSourceFile.id));
    expect(sourceFile.path, orderedEquals(ogSourceFile.path));
    expect(sourceFile.name, equals(ogSourceFile.name));
    expect(sourceFile.extension, equals(ogSourceFile.extension));
    expect(sourceFile.entry, equals(ogSourceFile.entry));
    await expectLater(sourceFile.hash, completion(await ogSourceFile.hash));
  });
}
