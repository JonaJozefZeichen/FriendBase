import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/birthday.dart';
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
  late final _tags = TextEditingController(
    text: widget.friend?.tags.join(', '),
  );
  late final _interval = TextEditingController(
    text: widget.friend?.callIntervalDays?.toString(),
  );
  late final _notes = TextEditingController(
    text: widget.friend?.notes ?? kNotesTemplate,
  );
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
      _tags,
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
      tags: _split(_tags, ',').map((t) => t.replaceFirst('#', '')).toList(),
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
          .showSnackBar(SnackBar(content: Text('!! could not save: $e')));
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
            child: const Text('[CANCEL]'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('[DELETE]'),
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
        title: Text(widget.friend == null ? 'NEW FRIEND' : 'EDIT'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('[SAVE]'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _field(
              _name,
              'name *',
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'name is required' : null,
            ),
            _field(_nickname, 'nickname'),
            _field(
              _birthday,
              'birthday (YYYY-MM-DD or --MM-DD)',
              keyboard: TextInputType.datetime,
              validator: (v) =>
                  (v ?? '').trim().isEmpty || Birthday.tryParse(v) != null
                  ? null
                  : 'use 1994-03-12, or --03-12 without year',
            ),
            _field(
              _phones,
              'phones (one per line)',
              keyboard: TextInputType.phone,
              lines: 2,
            ),
            _field(
              _emails,
              'emails (one per line)',
              keyboard: TextInputType.emailAddress,
              lines: 2,
            ),
            _field(_address, 'address', lines: 2),
            _field(_tags, 'tags (comma separated)'),
            _field(
              _interval,
              'call every N days (empty = default)',
              keyboard: TextInputType.number,
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return null;
                final n = int.tryParse(s);
                return n == null || n < 1 ? 'a whole number ≥ 1' : null;
              },
            ),
            _field(_notes, 'notes (markdown)', lines: 14),
            if (widget.friend != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving ? null : _confirmDelete,
                child: const Text('[ DELETE FRIEND ]'),
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
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
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
