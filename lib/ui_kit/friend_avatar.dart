import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/friend.dart';

/// The friend's profile picture, or their initials if they have none.
class FriendAvatar extends ConsumerWidget {
  const FriendAvatar({super.key, required this.friend, this.size = 44});

  final Friend friend;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(friendRepositoryProvider).avatarFile(friend);
    return AvatarCircle(name: friend.name, file: file, size: size);
  }
}

/// A round picture from [file], falling back to initials of [name].
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.file,
    this.size = 44,
  });

  final String name;
  final File? file;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = Text(
      _initials(name),
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: size * 0.36,
        color: colors.onSurface,
      ),
    );
    final scale = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: file == null
            ? initials
            : Image.file(
                file!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * scale).round(),
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p.characters.first.toUpperCase())
      .join();
}
