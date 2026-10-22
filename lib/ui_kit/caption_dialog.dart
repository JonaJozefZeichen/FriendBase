import 'package:flutter/material.dart';

/// Asks for an image's context. Returns the text, or null if dismissed.
///
/// [preview] shows the image being described, e.g. right after adding it;
/// [dismissLabel] reads `Skip` there instead of `Cancel`.
Future<String?> showCaptionDialog(
  BuildContext context, {
  String initial = '',
  Widget? preview,
  String dismissLabel = 'Cancel',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CaptionDialog(
      initial: initial,
      preview: preview,
      dismissLabel: dismissLabel,
    ),
  );
}

/// Owns its controller so it lives until the dialog has fully closed.
class _CaptionDialog extends StatefulWidget {
  const _CaptionDialog({
    required this.initial,
    required this.preview,
    required this.dismissLabel,
  });

  final String initial;
  final Widget? preview;
  final String dismissLabel;

  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What is this image about?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.preview != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 160, child: widget.preview),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. the cake she loved at her 30th',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.dismissLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
