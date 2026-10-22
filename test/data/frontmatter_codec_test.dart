import 'package:flutter_test/flutter_test.dart';
import 'package:friendbase/data/frontmatter_codec.dart';
import 'package:friendbase/domain/friend.dart';

const _sample = '''---
id: 01JB8XAAAAAAAAAAAAAAAAAAAA
name: Anna Müller
nickname: Anni
birthday: 1994-03-12
phones:
  - "+43 660 1234567"
emails: []
address: Hauptstraße 1, 1010 Wien
tags:
  - uni
  - close
call_interval_days: 30
calls:
  - 2026-09-02T19:40
  - 2026-10-15T20:05
images:
  - file: assets/cake.jpg
    caption: Her favourite cake, from Café Sacher
  - file: assets/peonies.jpg
created: 2026-10-22
mood: sunny
---

## Food
- Loves pho, hates cilantro

![cake](assets/cake.jpg)
''';

void main() {
  group('decodeFriend', () {
    test('reads every known field', () {
      final f = decodeFriend(_sample, folder: 'anna-mueller');
      expect(f.id, '01JB8XAAAAAAAAAAAAAAAAAAAA');
      expect(f.name, 'Anna Müller');
      expect(f.folder, 'anna-mueller');
      expect(f.birthday!.year, 1994);
      expect(f.phones, ['+43 660 1234567']);
      expect(f.emails, isEmpty);
      expect(f.address, 'Hauptstraße 1, 1010 Wien');
      expect(f.tags, ['uni', 'close']);
      expect(f.callIntervalDays, 30);
      expect(f.lastCall, DateTime(2026, 10, 15, 20, 5));
      expect(f.notes, startsWith('## Food'));
      expect(f.extra, {'mood': 'sunny'});
      expect(f.images.map((i) => i.file), [
        'assets/cake.jpg',
        'assets/peonies.jpg',
      ]);
      expect(f.images.first.caption, 'Her favourite cake, from Café Sacher');
      expect(f.images.last.caption, isEmpty);
    });

    test('round-trips without changes', () {
      final once = encodeFriend(decodeFriend(_sample, folder: 'a'));
      expect(once, _sample);
      expect(encodeFriend(decodeFriend(once, folder: 'a')), once);
    });

    test('tolerates hand-written files', () {
      final f = decodeFriend(
        '---\nphones: 0660123\ntags: solo\n---\nhi',
        folder: 'marko',
      );
      expect(f.name, 'marko');
      expect(f.id, isNotEmpty);
      expect(f.phones, ['0660123']);
      expect(f.tags, ['solo']);
      expect(f.notes, 'hi');
    });

    test('file without frontmatter is all notes', () {
      final f = decodeFriend('just text', folder: 'x');
      expect(f.notes, 'just text');
    });

    test('a --- inside a value does not end the frontmatter', () {
      final f = decodeFriend('---\nname: a---b\n---\nbody', folder: 'x');
      expect(f.name, 'a---b');
      expect(f.notes, 'body');
    });

    test('invalid YAML throws FormatException', () {
      expect(
        () => decodeFriend('---\nname: [oops\n---\n', folder: 'x'),
        throwsFormatException,
      );
    });
  });

  group('encodeMarkdown quoting', () {
    String roundTrip(String value) {
      final text = encodeMarkdown({'v': value}, '');
      return parseMarkdown(text).frontmatter['v'] as String;
    }

    for (final tricky in [
      'yes',
      'null',
      '123',
      '1.5',
      '0x1F',
      '--03-12',
      '+43 1',
      'a: b',
      '#tag',
      'trailing ',
      'quote "x"',
      'line\nbreak',
      '',
      'Čuvar Đorđe',
    ]) {
      test('keeps "$tricky" a string', () => expect(roundTrip(tricky), tricky));
    }

    test('dates stay plain and readable', () {
      expect(
        encodeMarkdown({'d': '2026-10-15T20:05'}, ''),
        '---\nd: 2026-10-15T20:05\n---\n',
      );
    });

    test('preserves nested extra values', () {
      final fm = {
        'links': {'insta': '@anna', 'site': 'https://a.example'},
        'list': [
          {'a': 1},
        ],
      };
      final parsed = parseMarkdown(encodeMarkdown(fm, '')).frontmatter;
      expect(parsed, fm);
    });
  });

  test('withCall / withoutLastCall', () {
    var f = const Friend(id: '1', name: 'A');
    f = f.withCall(DateTime(2026, 1, 1, 9, 5));
    f = f.withCall(DateTime(2026, 2, 1, 10, 0));
    expect(f.calls, ['2026-01-01T09:05', '2026-02-01T10:00']);
    expect(f.withoutLastCall().calls, ['2026-01-01T09:05']);
  });
}
