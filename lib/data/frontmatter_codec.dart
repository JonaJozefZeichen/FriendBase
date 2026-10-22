import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../domain/friend.dart';
import '../domain/ulid.dart';

/// A Markdown file split into its YAML frontmatter and body.
class MarkdownDoc {
  const MarkdownDoc(this.frontmatter, this.body);

  final Map<String, Object?> frontmatter;
  final String body;
}

final _frontmatterPattern = RegExp(
  r'^---\r?\n(?:([\s\S]*?)\r?\n)?---[ \t]*(?:\r?\n|$)',
);

/// Splits [text] into frontmatter and body. A file without frontmatter is
/// all body; malformed YAML throws a [FormatException].
MarkdownDoc parseMarkdown(String text) {
  final match = _frontmatterPattern.firstMatch(text);
  if (match == null) return MarkdownDoc(const {}, text);
  final body = text.substring(match.end).replaceFirst(RegExp(r'^(\r?\n)+'), '');
  final YamlNode yaml;
  try {
    yaml = loadYamlNode(match[1] ?? '');
  } on YamlException catch (e) {
    throw FormatException('Invalid frontmatter: ${e.message}');
  }
  if (yaml is YamlScalar && yaml.value == null) {
    return MarkdownDoc(const {}, body);
  }
  if (yaml is! YamlMap) {
    throw const FormatException('Frontmatter must be a key: value map');
  }
  return MarkdownDoc(_toPlain(yaml) as Map<String, Object?>, body);
}

/// Joins [frontmatter] and [body] into a Markdown file. Null values are
/// omitted; key order is preserved.
String encodeMarkdown(Map<String, Object?> frontmatter, String body) {
  final yaml = StringBuffer();
  for (final entry in frontmatter.entries) {
    if (entry.value == null) continue;
    _writeEntry(yaml, entry.key, entry.value, 0);
  }
  final trimmedBody = body.replaceFirst(RegExp(r'^(\r?\n)+'), '').trimRight();
  final suffix = trimmedBody.isEmpty ? '' : '\n$trimmedBody\n';
  return '---\n$yaml---\n$suffix';
}

/// Reads a friend from the contents of their `friend.md`.
Friend decodeFriend(String text, {required String folder}) {
  final doc = parseMarkdown(text);
  final fm = Map<String, Object?>.of(doc.frontmatter);

  String? str(String key) {
    final value = fm.remove(key);
    final s = value?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  List<String> list(String key) {
    final value = fm.remove(key);
    if (value == null) return const [];
    final items = value is List ? value : [value];
    return items
        .where((e) => e != null)
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<FriendImage> images() {
    final value = fm.remove('images');
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map && item['file'] != null)
          FriendImage(
            file: item['file'].toString(),
            caption: item['caption']?.toString() ?? '',
          )
        else if (item is String && item.isNotEmpty)
          FriendImage(file: item),
    ];
  }

  final interval = str('call_interval_days');
  return Friend(
    id: str('id') ?? newUlid(),
    name: str('name') ?? folder,
    folder: folder,
    nickname: str('nickname'),
    birthdayRaw: str('birthday'),
    phones: list('phones'),
    emails: list('emails'),
    address: str('address'),
    avatar: str('avatar'),
    callIntervalDays: interval == null ? null : int.tryParse(interval),
    calls: list('calls'),
    images: images(),
    created: str('created'),
    notes: doc.body,
    extra: fm,
  );
}

/// Serializes a friend to the contents of their `friend.md`.
String encodeFriend(Friend f) {
  String? orNull(String? s) => s == null || s.trim().isEmpty ? null : s;
  return encodeMarkdown({
    'id': f.id,
    'name': f.name,
    'nickname': orNull(f.nickname),
    'birthday': orNull(f.birthdayRaw),
    'phones': f.phones,
    'emails': f.emails,
    'address': orNull(f.address),
    'avatar': orNull(f.avatar),
    'call_interval_days': f.callIntervalDays,
    'calls': f.calls,
    'images': [
      for (final image in f.images)
        {
          'file': image.file,
          if (image.caption.trim().isNotEmpty) 'caption': image.caption,
        },
    ],
    'created': orNull(f.created),
    ...f.extra,
  }, f.notes);
}

Object? _toPlain(YamlNode node) {
  if (node is YamlMap) {
    return {
      for (final e in node.nodes.entries)
        (e.key as YamlNode).value.toString(): _toPlain(e.value),
    };
  }
  if (node is YamlList) return node.nodes.map(_toPlain).toList();
  final value = node.value;
  // An unquoted `0660123` would become the number 660123; keep the source
  // text whenever reading it as a number would change it.
  if (value is num && node.span.text != value.toString()) return node.span.text;
  return value;
}

void _writeEntry(StringBuffer out, String key, Object? value, int indent) {
  final pad = ' ' * indent;
  final k = _scalar(key);
  if (value is Map && value.isNotEmpty) {
    out.writeln('$pad$k:');
    for (final e in value.entries) {
      _writeEntry(out, e.key.toString(), e.value, indent + 2);
    }
  } else if (value is List && value.isNotEmpty) {
    out.writeln('$pad$k:');
    for (final item in value) {
      _writeListItem(out, item, indent + 2);
    }
  } else {
    out.writeln('$pad$k: ${_inline(value)}');
  }
}

void _writeListItem(StringBuffer out, Object? item, int indent) {
  final pad = ' ' * indent;
  if (item is Map && item.isNotEmpty) {
    // Block style: the first key goes on the dash line, the rest align below.
    final entries = StringBuffer();
    for (final e in item.entries) {
      _writeEntry(entries, e.key.toString(), e.value, indent + 2);
    }
    out.write('$pad- ${entries.toString().substring(indent + 2)}');
  } else if (item is List && item.isNotEmpty) {
    // Lists of lists are rare in hand-written frontmatter; flow style
    // (JSON) is valid YAML and keeps the emitter small.
    out.writeln('$pad- ${jsonEncode(item)}');
  } else {
    out.writeln('$pad- ${_inline(item)}');
  }
}

String _inline(Object? value) {
  if (value == null) return 'null';
  if (value is Map) return '{}';
  if (value is List) return '[]';
  if (value is num || value is bool) return value.toString();
  return _scalar(value.toString());
}

final _plainSafe = RegExp(
  r'^[\p{L}\p{N}][\p{L}\p{N} _.,:/()@+\-]*$',
  unicode: true,
);
const _reserved = {
  'true',
  'false',
  'yes',
  'no',
  'on',
  'off',
  'null',
  '~',
  'y',
  'n',
};

/// Writes a string plain when YAML would read it back unchanged, otherwise
/// double-quoted (JSON string syntax is valid YAML).
String _scalar(String s) {
  final needsQuotes =
      !_plainSafe.hasMatch(s) ||
      s.endsWith(' ') ||
      s.endsWith(':') ||
      s.contains(': ') ||
      _reserved.contains(s.toLowerCase()) ||
      num.tryParse(s) != null ||
      RegExp(r'^0[0-7]+$|^0x|^0o').hasMatch(s);
  return needsQuotes ? jsonEncode(s) : s;
}
