import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/friend.dart';
import '../../ui_kit/widgets.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/ledger.dart';
import '../../ui_kit/caption_dialog.dart';

/// A friend's images full screen: swipe or use the arrows to move between them,
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

    // Uses the app's chosen theme, like every other screen.
    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (friend == null || images.isEmpty)
              Center(child: Text(context.l10n.noImages))
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
                          ? Text(context.l10n.imagePathNotAllowed)
                          : Image.file(
                              file,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Text(
                                context.l10n.missingFile(images[i].file),
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
                  padding: const EdgeInsets.only(left: 8),
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
                  padding: const EdgeInsets.only(right: 8),
                  child: FloatingRoundButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: context.l10n.nextImage,
                    onPressed: () => _go(index + 1),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const BackRoundButton(),
                    Expanded(
                      // heightFactor keeps this row as tall as its buttons;
                      // a plain Center would stretch it to the full screen.
                      child: Center(
                        heightFactor: 1,
                        child: images.isEmpty
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
                      const SizedBox(width: 44),
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
                  child: _CaptionCard(
                    caption: images[index].caption,
                    onTap: () => _editCaption(context, friend, images[index]),
                  ),
                ),
              ),
          ],
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

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// The image's context, floating over the bottom of the image.
class _CaptionCard extends StatelessWidget {
  const _CaptionCard({required this.caption, required this.onTap});

  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24, maxHeight: 160),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      caption.isEmpty ? context.l10n.tapToAddContext : caption,
                      style: caption.isEmpty
                          ? TextStyle(color: Theme.of(context).hintColor)
                          : const TextStyle(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
