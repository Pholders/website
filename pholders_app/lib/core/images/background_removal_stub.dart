import 'dart:typed_data';

/// Off the web there is no browser to do the work in, so the photo is left
/// as it is. The doctor app only ships to the web; this exists so the file
/// still compiles under `flutter test`, which runs on the VM.
Future<Uint8List?> removeBackground(
  Uint8List bytes,
  String mimeType, {
  required int maxEdge,
}) async {
  return null;
}
