import 'birthday.dart';

/// One friend, as stored in `friends/<folder>/friend.md`.
///
/// Fields that come straight from the file (`birthday`, `calls`, `created`)
/// are kept as raw strings so hand-edited values are never lost on save;
/// typed views are exposed through getters.
class Friend {
  const Friend({
    required this.id,
    required this.name,
    this.folder = '',
    this.nickname,
    this.birthdayRaw,
    this.phones = const [],
    this.emails = const [],
    this.address,
    this.avatar,
    this.callIntervalDays,
    this.calls = const [],
    this.images = const [],
    this.created,
    this.notes = '',
    this.extra = const {},
  });

  final String id;
  final String name;

  /// Folder name inside `friends/`. Empty for a friend not yet saved.
  final String folder;
  final String? nickname;
  final String? birthdayRaw;
  final List<String> phones;
  final List<String> emails;
  final String? address;

  /// Path relative to the friend's folder, e.g. `assets/avatar.jpg`.
  final String? avatar;

  /// Overrides the app-wide default reminder interval when set.
  final int? callIntervalDays;

  /// Append-only call log as `YYYY-MM-DDTHH:MM` strings, newest last.
  final List<String> calls;

  /// Reference images in the friend's `assets/` folder, in display order.
  final List<FriendImage> images;
  final String? created;

  /// Free Markdown body below the frontmatter.
  final String notes;

  /// Frontmatter keys the app doesn't know, preserved as-is.
  final Map<String, Object?> extra;

  Birthday? get birthday => Birthday.tryParse(birthdayRaw);

  /// Parsed call times, oldest first. Entries that don't parse are skipped.
  List<DateTime> get callTimes {
    final times = calls.map(DateTime.tryParse).whereType<DateTime>().toList();
    times.sort();
    return times;
  }

  DateTime? get lastCall {
    final times = callTimes;
    return times.isEmpty ? null : times.last;
  }

  Friend withCall(DateTime at) =>
      copyWith(calls: [...calls, formatCallTime(at)]);

  /// Removes the most recent call entry, if any.
  Friend withoutLastCall() {
    final last = lastCall;
    if (last == null) return this;
    final index = calls.lastIndexWhere((c) => DateTime.tryParse(c) == last);
    return copyWith(calls: [...calls]..removeAt(index));
  }

  Friend copyWith({
    String? folder,
    String? name,
    String? Function()? nickname,
    String? Function()? birthdayRaw,
    List<String>? phones,
    List<String>? emails,
    String? Function()? address,
    String? Function()? avatar,
    int? Function()? callIntervalDays,
    List<String>? calls,
    List<FriendImage>? images,
    String? created,
    String? notes,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      folder: folder ?? this.folder,
      nickname: nickname != null ? nickname() : this.nickname,
      birthdayRaw: birthdayRaw != null ? birthdayRaw() : this.birthdayRaw,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      address: address != null ? address() : this.address,
      avatar: avatar != null ? avatar() : this.avatar,
      callIntervalDays: callIntervalDays != null
          ? callIntervalDays()
          : this.callIntervalDays,
      calls: calls ?? this.calls,
      images: images ?? this.images,
      created: created ?? this.created,
      notes: notes ?? this.notes,
      extra: extra,
    );
  }
}

/// A reference image with an optional caption giving its context.
class FriendImage {
  const FriendImage({required this.file, this.caption = ''});

  /// Path relative to the friend's folder, e.g. `assets/20261022-1912.jpg`.
  final String file;
  final String caption;

  FriendImage copyWith({String? caption}) =>
      FriendImage(file: file, caption: caption ?? this.caption);
}

/// Formats a call time with minute precision, e.g. `2026-10-15T20:05`.
String formatCallTime(DateTime t) =>
    '${formatDate(t)}T'
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Formats a date as `YYYY-MM-DD`.
String formatDate(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Shown in grey where a friend's notes are still empty: anything goes.
const kNotesHint = 'Facts, Favourites, etc..';
