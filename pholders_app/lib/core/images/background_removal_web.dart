import 'dart:js_interop';
import 'dart:typed_data';

/// The function `web/index.html` puts on `window`. It resolves the library
/// from a CDN on first use, so this call is slow the first time — tens of
/// seconds on a cold cache, because the model has to come down — and quick
/// afterwards.
@JS('pholdersRemoveBackground')
external JSFunction? get _remover;

/// Cuts the background out in the browser. Null if it could not be done.
///
/// Every failure is the same answer: the script never loaded, the CDN is
/// blocked, the tab ran out of memory, the photo defeated the model. The
/// caller uploads the original in each case, so none of them costs the
/// doctor their upload.
Future<Uint8List?> removeBackground(Uint8List bytes, String mimeType) async {
  final remover = _remover;
  if (remover == null) return null;

  try {
    final result = remover.callAsFunction(
      null,
      bytes.toJS,
      mimeType.toJS,
    ) as JSPromise<JSUint8Array>?;
    if (result == null) return null;

    final cutout = (await result.toDart).toDart;
    // An empty result is a failure dressed as success; treat it as one.
    return cutout.isEmpty ? null : cutout;
  } catch (_) {
    return null;
  }
}
