import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../app/providers.dart';
import '../../domain/birthday.dart';
import '../../domain/call_status.dart';
import '../../domain/friend.dart';
import '../../domain/ulid.dart';
import '../../domain/date_format.dart';
import '../../l10n/l10n.dart';
import '../../ui_kit/birthday_picker.dart';
import '../../ui_kit/friend_avatar.dart';
import '../../ui_kit/image_source_sheet.dart';

/// Create a friend (when [friend] is null) or edit an existing one.
class FriendEditScreen extends ConsumerStatefulWidget {
  const FriendEditScreen({super.key, this.friend});

  final Friend? friend;

  @override
  ConsumerState<FriendEditScreen> createState() => _FriendEditScreenState();
}

class _FriendEditScreenState extends ConsumerState<FriendEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.friend?.name);
  late final _nickname = TextEditingController(text: widget.friend?.nickname);
  late final _birthday = TextEditingController(
    text: widget.friend?.birthdayRaw,
  );
  late final _phones = TextEditingController(
    text: widget.friend?.phones.join('\n'),
  );
  late final _emails = TextEditingController(
    text: widget.friend?.emails.join('\n'),
  );
  late final _address = TextEditingController(text: widget.friend?.address);
  late final _interval = TextEditingController(
    text: widget.friend?.callIntervalDays?.toString(),
  );
  late final _notes = TextEditingController(text: widget.friend?.notes);
  bool _saving = false;

  /// A newly picked profile picture, applied on save.
  String? _pendingAvatar;

  /// The existing profile picture should be removed on save.
  bool _avatarRemoved = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _nickname,
      _birthday,
      _phones,
      _emails,
      _address,
      _interval,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  static List<String> _split(TextEditingController c, Pattern by) =>
      c.text.split(by).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.friend ?? Friend(id: newUlid(), name: '');
    final interval = _optional(_interval);
    final updated = base.copyWith(
      name: _name.text.trim(),
      nickname: () => _optional(_nickname),
      birthdayRaw: () => _optional(_birthday),
      phones: _split(_phones, '\n'),
      emails: _split(_emails, '\n'),
      address: () => _optional(_address),
      callIntervalDays: () => interval == null ? null : int.parse(interval),
      notes: _notes.text,
    );
    try {
      final notifier = ref.read(friendsProvider.notifier);
      final saved = await notifier.save(updated);
      if (_pendingAvatar != null) {
        await notifier.setAvatar(saved, _pendingAvatar!);
      } else if (_avatarRemoved && saved.avatar != null) {
        await notifier.removeAvatar(saved);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$e'))));
    }
  }

  Future<void> _confirmDelete() async {
    final friend = widget.friend!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteFriendTitle(friend.name)),
        content: Text(context.l10n.deleteFriendBody),
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
    if (confirmed != true || !mounted) return;
    await ref.read(friendsProvider.notifier).delete(friend);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.friend == null
              ? context.l10n.newFriend
              : context.l10n.editFriend,
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(context.l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _avatarPicker(),
            const SizedBox(height: 16),
            _field(
              _name,
              context.l10n.name,
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? context.l10n.nameRequired : null,
            ),
            _field(
              _nickname,
              context.l10n.nickname,
              icon: Icons.badge_outlined,
            ),
            _birthdayField(),
            _field(
              _phones,
              context.l10n.phoneNumbers,
              icon: Icons.phone_outlined,
              helper: context.l10n.onePerLine,
              keyboard: TextInputType.phone,
              lines: 2,
            ),
            _field(
              _emails,
              context.l10n.emails,
              icon: Icons.mail_outline_rounded,
              helper: context.l10n.onePerLine,
              keyboard: TextInputType.emailAddress,
              lines: 2,
            ),
            _field(
              _address,
              context.l10n.address,
              icon: Icons.home_outlined,
              lines: 2,
            ),
            _field(
              _interval,
              context.l10n.callEvery,
              icon: Icons.update_rounded,
              helper: context.l10n.callEveryHelper(kDefaultCallIntervalDays),
              keyboard: TextInputType.number,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                final n = int.tryParse(s);
                return n == null || n < 1 ? context.l10n.wholeNumber : null;
              },
            ),
            _field(
              _notes,
              context.l10n.notes,
              lines: 12,
              hint: context.l10n.notesHint,
            ),
            if (widget.friend != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(context.l10n.deleteFriend),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Read-only; tapping opens the day · month · year wheels. [_birthday]
  /// holds the value as stored in the file.
  Widget _birthdayField() {
    final raw = _birthday.text.trim();
    final birthday = Birthday.tryParse(raw);
    final style = ref.watch(settingsProvider.select((s) => s.dateStyle));
    final shown = birthday == null
        ? raw // Unparseable hand-edited value: show it untouched.
        : formatDay(
            style,
            day: birthday.day,
            month: birthday.month,
            year: birthday.year,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final picked = await showBirthdayPicker(context, initial: birthday);
          if (picked != null) setState(() => _birthday.text = picked);
        },
        child: InputDecorator(
          isEmpty: shown.isEmpty,
          decoration: InputDecoration(
            labelText: context.l10n.birthday,
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: shown.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.clearBirthday,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_birthday.clear),
                  ),
          ),
          child: Text(shown.isEmpty ? ' ' : shown),
        ),
      ),
    );
  }

  Widget _avatarPicker() {
    final existing = widget.friend == null || _avatarRemoved
        ? null
        : ref.watch(friendRepositoryProvider).avatarFile(widget.friend!);
    final file = _pendingAvatar != null ? File(_pendingAvatar!) : existing;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        button: true,
        label: context.l10n.profilePicture,
        child: GestureDetector(
          onTap: () => _pickAvatar(hasOne: file != null),
          child: Stack(
            children: [
              ValueListenableBuilder(
                valueListenable: _name,
                builder: (_, name, _) =>
                    AvatarCircle(name: name.text, file: file, size: 96),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.onSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: colors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar({required bool hasOne}) async {
    final choice = await showImageSourceSheet(
      context,
      removeLabel: hasOne ? context.l10n.removePicture : null,
    );
    if (choice == false) {
      setState(() {
        _pendingAvatar = null;
        _avatarRemoved = true;
      });
      return;
    }
    if (choice is! ImageSource) return;
    try {
      final path = await ref.read(imagePickerProvider)(choice);
      if (path == null || !mounted) return;
      setState(() {
        _pendingAvatar = path;
        _avatarRemoved = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotPickPicture('$e'))),
      );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    String? hint,
    String? helper,
    IconData? icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          hintText: hint,
          helperText: helper,
          prefixIcon: icon == null ? null : Icon(icon),
          // Keep the label out of the way so the hint is always visible.
          floatingLabelBehavior: hint == null
              ? null
              : FloatingLabelBehavior.always,
        ),
        minLines: lines,
        maxLines: lines == 1 ? 1 : null,
        keyboardType: lines > 1 && keyboard == null
            ? TextInputType.multiline
            : keyboard,
        validator: validator,
      ),
    );
  }
}
