import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../l10n/l10n.dart';

/// Asks where a picture should come from. Null if dismissed, or `false`
/// for the optional [removeLabel] entry.
Future<Object?> showImageSourceSheet(
  BuildContext context, {
  String? removeLabel,
}) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return showModalBottomSheet<Object>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.chooseFromGallery),
              shape: shape,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.takePhoto),
              shape: shape,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (removeLabel != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(removeLabel),
                shape: shape,
                onTap: () => Navigator.pop(context, false),
              ),
          ],
        ),
      ),
    ),
  );
}
