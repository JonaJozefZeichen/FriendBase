import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/friend.dart';
import '../../ui_kit/ascii.dart';
import '../../ui_kit/caption_dialog.dart';

/// A friend's images full screen: swipe or use `<` `>` to move between them,
/// tap the caption box at the bottom to write what the image is about.
class ImageViewScreen extends ConsumerStatefulWidget {
  const ImageViewScreen({
    super.key,
    required this.friendId,
    this.initialIndex = 0,
  });

  final String friendId;
  final int initialIndex;

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
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider).value ?? const [];
    final friend = friends.where((f) => f.id == widget.friendId).firstOrNull;
    final images = friend?.images ?? const <FriendImage>[];
    final repo = ref.watch(friendRepositoryProvider);
    final index = images.isEmpty ? 0 : _index.clamp(0, images.length - 1);

    // Always dark, so photos stand out; the monochrome theme just inverts.
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(
        builder: (context) => Scaffold(
          body: Stack(
            children: [
              if (friend == null || images.isEmpty)
                const Center(child: Text('no images.'))
              else
                PageView.builder(
                  controller: _pages,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final file = repo.imageFile(friend, images[i]);
                    return InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: file == null
                            ? const Text('? unsafe path')
                            : Image.file(
                                file,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    Text('? missing ${images[i].file}'),
                              ),
                      ),
                    );
                  },
                ),
              if (index > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Arrow(label: '<', onTap: () => _go(index - 1)),
                ),
              if (index < images.length - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: _Arrow(label: '>', onTap: () => _go(index + 1)),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SquareButton(
                        label: '<',
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Text(
                          images.isEmpty
                              ? ''
                              : '${index + 1} / ${images.length}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (friend != null && images.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              _confirmRemove(context, friend, images[index]),
                          child: const Text('[DELETE]'),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              if (friend != null && images.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 16),
                    child: _CaptionBox(
                      caption: images[index].caption,
                      onTap: () => _editCaption(context, friend, images[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        title: const Text('Delete this image?'),
        content: const Text('The file is removed from the friend\'s folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('[CANCEL]'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('[DELETE]'),
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

class _Arrow extends StatelessWidget {
  const _Arrow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 96,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _CaptionBox extends StatelessWidget {
  const _CaptionBox({required this.caption, required this.onTap});

  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.85),
      shape: Border.all(color: colors.onSurface),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 160),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  caption.isEmpty ? 'tap to add context_' : caption,
                  style: caption.isEmpty
                      ? TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
