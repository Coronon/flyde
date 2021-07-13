import 'dart:io';

/// Connection between source file and coresponding object file.
///
/// Provides the path to both files and an event handler which should
/// be called as soon as the object file has been created by the compiler.
class ImplementationObjectRef {
  /// A reference to the source file.
  final File source;

  /// A reference to the object file.
  final File object;

  final Future<void> Function() _onLink;

  ImplementationObjectRef(this.source, this.object, this._onLink);

  /// Method to call as soon as the compiler has created the object file.
  Future<void> link() async {
    await _onLink();
  }
}
