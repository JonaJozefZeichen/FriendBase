import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/birthday.dart';
import '../../domain/call_status.dart';
import '../../domain/friend.dart';
import '../../domain/ulid.dart';

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
      await ref.read(friendsProvider.notifier).save(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _confirmDelete() async {
    final friend = widget.friend!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${friend.name}?'),
        content: const Text('Their file, notes and images will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
        title: Text(widget.friend == null ? 'New friend' : 'Edit friend'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _field(
              _name,
              'Name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Please enter a name' : null,
            ),
            _field(_nickname, 'Nickname', icon: Icons.badge_outlined),
            _field(
              _birthday,
              'Birthday',
              icon: Icons.cake_outlined,
              helper: 'YYYY-MM-DD, or --MM-DD without the year',
              keyboard: TextInputType.datetime,
              validator: (v) =>
                  (v ?? '').trim().isEmpty || Birthday.tryParse(v) != null
                  ? null
                  : 'Use 1994-03-12, or --03-12 without the year',
            ),
            _field(
              _phones,
              'Phone numbers',
              icon: Icons.phone_outlined,
              helper: 'One per line',
              keyboard: TextInputType.phone,
              lines: 2,
            ),
            _field(
              _emails,
              'Emails',
              icon: Icons.mail_outline_rounded,
              helper: 'One per line',
              keyboard: TextInputType.emailAddress,
              lines: 2,
            ),
            _field(_address, 'Address', icon: Icons.home_outlined, lines: 2),
            _field(
              _interval,
              'Call every … days',
              icon: Icons.update_rounded,
              helper: 'Leave empty for the default ($kDefaultCallIntervalDays)',
              keyboard: TextInputType.number,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                final n = int.tryParse(s);
                return n == null || n < 1 ? 'A whole number, 1 or more' : null;
              },
            ),
            _field(_notes, 'Notes', lines: 12, hint: kNotesHint),
            if (widget.friend != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete friend'),
              ),
            ],
          ],
        ),
      ),
    );
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
