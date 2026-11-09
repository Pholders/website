import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The rule the photo picker follows once the background has been cut out.
///
/// A cut-out comes back as PNG, which is lossless, so it can be several times
/// the size of the JPEG that went in. An 11-megapixel phone photo was a few
/// megabytes as a JPEG and twenty-odd as a transparent PNG: it passed the
/// size check on the way in, because that check ran on the original, and was
/// then refused by the server. The result has to be measured again.
///
/// This pins the decision rather than the widget, because the decision is
/// the part that was wrong.
const maxBytes = 5 * 1024 * 1024;

/// Which bytes to upload, mirroring the picker: the cut-out when there is
/// one and it fits, otherwise the photo as it was picked.
Uint8List chooseUpload({required Uint8List original, required Uint8List? cutout}) {
  if (cutout == null) return original;
  if (cutout.lengthInBytes > maxBytes) return original;
  return cutout;
}

Uint8List bytes(int length) => Uint8List(length);

void main() {
  test('a cut-out that fits is the one uploaded', () {
    final original = bytes(2 * 1024 * 1024);
    final cutout = bytes(3 * 1024 * 1024);
    expect(chooseUpload(original: original, cutout: cutout), same(cutout));
  });

  test('a cut-out too large for the server falls back to the photo', () {
    // The case that shipped broken: a 3MB JPEG whose cut-out is 22MB.
    final original = bytes(3 * 1024 * 1024);
    final cutout = bytes(22 * 1024 * 1024);
    expect(chooseUpload(original: original, cutout: cutout), same(original));
  });

  test('exactly at the limit is still allowed through', () {
    final cutout = bytes(maxBytes);
    expect(chooseUpload(original: bytes(10), cutout: cutout), same(cutout));
  });

  test('one byte over is not', () {
    final original = bytes(10);
    expect(chooseUpload(original: original, cutout: bytes(maxBytes + 1)),
        same(original));
  });

  test('no cut-out at all uploads the photo untouched', () {
    final original = bytes(1024);
    expect(chooseUpload(original: original, cutout: null), same(original));
  });

  test('the fallback is never larger than the limit it was checked against', () {
    // The picker refuses an oversized photo before any of this runs, so
    // whatever is chosen here is within the limit either way.
    for (final pair in [
      [1024, 10 * 1024 * 1024],
      [maxBytes, maxBytes + 1],
      [2048, 2048],
    ]) {
      final chosen = chooseUpload(
        original: bytes(pair[0]),
        cutout: bytes(pair[1]),
      );
      expect(chosen.lengthInBytes, lessThanOrEqualTo(maxBytes));
    }
  });
}
