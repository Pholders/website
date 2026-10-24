import 'dart:typed_data';

import 'background_removal_stub.dart'
    if (dart.library.js_interop) 'background_removal_web.dart' as impl;

/// Cuts the background out of a photo, returning a transparent PNG.
///
/// Runs in the browser, on the machine of whoever is uploading. It cannot run
/// on the server: one removal peaks at roughly 1GB of memory — measured, and
/// the same for a small photo as a large one, because the cost is the model
/// rather than the picture — while the API container has 512MB. The process
/// was killed part-way through every upload, which returned an empty 502 and
/// took the whole API down with it for about a minute.
///
/// Returns null when the background could not be removed, for any reason:
/// the library failed to load, the browser ran out of memory, or this is not
/// a web build. Callers upload the original photo in that case, so a photo
/// keeping its background is the worst outcome rather than a lost upload.
Future<Uint8List?> removeBackground(Uint8List bytes, String mimeType) {
  return impl.removeBackground(bytes, mimeType);
}
