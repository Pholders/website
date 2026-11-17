@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A dropdown sizes its internal row to its widest item unless told not to.
/// Give it less width than that and it overflows, which is what the console
/// reports as "A RenderFlex overflowed by 35 pixels on the right" from
/// DropdownButtonFormField. `isExpanded: true` makes it take the width it is
/// given and ellipsize instead.
///
/// This reads the source rather than pumping widgets on purpose. The fault
/// only appears below a certain window width, so catching it through the
/// widget tree would mean rendering every screen that has a dropdown at
/// every width worth worrying about. Thirteen of these shipped overflowing;
/// scanning for the property catches the next one the moment it is written.
void main() {
  test('every dropdown sets isExpanded, so none can overflow when narrowed', () {
    final offenders = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();

      for (final match in RegExp(r'Dropdown(?:ButtonFormField|Button)(?:<[^>]*>)?\s*\(')
          .allMatches(source)) {
        final body = _argumentsOf(source, match.end);
        if (body.contains('isExpanded')) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path.replaceAll(r'\', '/')}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These dropdowns will overflow when the window is narrow enough '
          'that their widest item no longer fits. Add isExpanded: true:\n'
          '  ${offenders.join('\n  ')}',
    );
  });
}

/// The text between the constructor's parentheses, balanced so a nested call
/// does not end the search early.
String _argumentsOf(String source, int openParenEnd) {
  var depth = 1;
  var i = openParenEnd;
  while (i < source.length && depth > 0) {
    final char = source[i];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
    }
    i++;
  }
  return source.substring(openParenEnd, i);
}
