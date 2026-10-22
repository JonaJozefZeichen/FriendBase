import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/features/about/privacy_policy.dart';

/// PRIVACY.md (for app stores / GitHub) must say exactly what the app shows.
void main() {
  test('PRIVACY.md matches the in-app privacy policy', () {
    final md = File('PRIVACY.md').readAsStringSync();
    expect(md, contains('Effective $kPrivacyEffectiveDate'));
    for (final (heading, body) in kPrivacySections) {
      expect(md, contains('## $heading\n\n$body\n'), reason: heading);
    }
  });
}
