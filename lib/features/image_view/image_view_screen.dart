import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/friend.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/caption_dialog.dart';
import '../../ui_kit/widgets.dart';

/// Hero tag shared by a polaroid thumbnail and its enlarged photo.
String imageHeroTag(Friend friend, FriendImage image) =>
    'image-${friend.id}-${image.file}';

/// A friend's pictures, lifted out of the friend view: a large polaroid
/// hovering above the blurred, dimmed friend view. Swipe or use the arrows
/// to move between pictures; tap the caption to describe the picture; tap
/// outside or ✕ to put it back.
class ImageViewScreen extends ConsumerStatefulWidget {
  const ImageViewScreen({
    super.key,
    required this.friendId,
    this.initialIndex = 0,
  });

  final String friendId;
  final int initialIndex;

  /// A see-through route, so the friend view stays visible underneath.
  static Route<void> route({required String friendId, int initialIndex = 0}) =>
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) =>
            ImageViewScreen(friendId: friendId, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

  @override
  ConsumerState<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends ConsumerState<ImageViewScreen> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider).value ?? const [];
    final friend = friends.where((f) => f.id == widget.friendId).firstOrNull;
    final images = friend?.images ?? const <FriendImage>[];
    final repo = ref.watch(friendRepositoryProvider);
    final index = images.isEmpty ? 0 : _index.clamp(0, images.length - 1);
    final paper = LedgerTokens.of(context).paper;
    final dark = paper.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final photoSide = (size.width - 64).clamp(200.0, size.height * 0.5);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // The friend view behind: blurred and dimmed; tap to close.
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(
                  color: (dark ? Colors.black : paper.ink).withValues(
                    alpha: dark ? 0.5 : 0.28,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        FloatingRoundButton(
                          icon: Icons.close_rounded,
                          tooltip: context.l10n.close,
                          onPressed: _close,
                        ),
                        Expanded(
                          child: Center(
                            child: images.length < 2
                                ? const SizedBox.shrink()
                                : _Pill('${index + 1} / ${images.length}'),
                          ),
                        ),
                        if (friend != null && images.isNotEmpty)
                          FloatingRoundButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: context.l10n.deleteImage,
                            onPressed: () =>
                                _confirmRemove(context, friend, images[index]),
                          )
                        else
                          const SizedBox(width: 46),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (friend == null || images.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(context.l10n.noImages),
                      )
                    else
                      _HoveringPolaroid(
                        dark: dark,
                        photo: SizedBox.square(
                          dimension: photoSide,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pages,
                                itemCount: images.length,
                                onPageChanged: (i) =>
                                    setState(() => _index = i),
                                itemBuilder: (_, i) {
                                  final file = repo.imageFile(
                                    friend,
                                    images[i],
                                  );
                                  return Hero(
                                    tag: imageHeroTag(friend, images[i]),
                                    child: InteractiveViewer(
                                      maxScale: 4,
                                      child: file == null
                                          ? Center(
                                              child: Text(
                                                context
                                                    .l10n
                                                    .imagePathNotAllowed,
                                              ),
                                            )
                                          : Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                              width: photoSide,
                                              height: photoSide,
                                              errorBuilder: (_, _, _) => Center(
                                                child: Text(
                                                  context.l10n.missingFile(
                                                    images[i].file,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              if (index > 0)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: FloatingRoundButton(
                                      icon: Icons.chevron_left_rounded,
                                      tooltip: context.l10n.previousImage,
                                      onPressed: () => _go(index - 1),
                                    ),
                                  ),
                                ),
                              if (index < images.length - 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FloatingRoundButton(
                                      icon: Icons.chevron_right_rounded,
                                      tooltip: context.l10n.nextImage,
                                      onPressed: () => _go(index + 1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        caption: _Caption(
                          caption: images[index].caption,
                          onTap: () =>
                              _editCaption(context, friend, images[index]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCaption(
    BuildContext context,
    Friend friend,
    FriendImage image,
  ) async {
    final caption = await showCaptionDialog(context, initial: image.caption);
    if (caption == null) return;
    await ref.read(friendsProvider.notifier).setCaption(friend, image, caption);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    Friend friend,
    FriendImage image,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteImageTitle),
        content: Text(context.l10n.deleteImageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = await ref
        .read(friendsProvider.notifier)
        .removeImage(friend, image);
    if (!context.mounted) return;
    if (updated.images.isEmpty) Navigator.of(context).maybePop();
  }
}

/// A big instant-camera frame with the caption written in its wide bottom
/// margin, floating with a soft shadow.
class _HoveringPolaroid extends StatelessWidget {
  const _HoveringPolaroid({
    required this.dark,
    required this.photo,
    required this.caption,
  });

  final bool dark;
  final Widget photo;
  final Widget caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2E2C34) : const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(child: photo),
          caption,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = LedgerTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.paper.card,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: tokens.data(weight: FontWeight.w600)),
    );
  }
}

/// The picture's context, written under the photo; tap to edit.
class _Caption extends StatelessWidget {
  const _Caption({required this.caption, required this.onTap});

  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = caption.isEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28, maxHeight: 140),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    empty ? context.l10n.tapToAddContext : caption,
                    style: empty
                        ? TextStyle(color: theme.hintColor)
                        : const TextStyle(height: 1.4, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
