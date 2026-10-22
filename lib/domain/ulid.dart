import 'dart:math';

const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32
final _random = Random.secure();

/// Generates a ULID: 10 chars of millisecond timestamp + 16 random chars.
/// Sortable by creation time and stable even if a friend's folder is renamed.
String newUlid([DateTime? now]) {
  var time = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final timePart = List.filled(10, '');
  for (var i = 9; i >= 0; i--) {
    timePart[i] = _alphabet[time % 32];
    time ~/= 32;
  }
  final randomPart = List.generate(
    16,
    (_) => _alphabet[_random.nextInt(32)],
  ).join();
  return timePart.join() + randomPart;
}
