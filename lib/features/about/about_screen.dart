import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../ui_kit/widgets.dart';
import 'privacy_policy.dart';

const _repoUrl = 'https://github.com/JonaJozefZeichen/FriendBase';
const _author = 'Jona Jožef Zeichen';
const _legalese =
    '© 2026 $_author\n'
    'Released under the MIT License.';

/// Version, where the data lives, privacy policy and licences.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final version = ref.watch(appVersionProvider).value ?? '…';
    final repo = ref.watch(friendRepositoryProvider);
    final count = ref.watch(friendsProvider).value?.length ?? 0;
    final problems = repo.problems;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    const gap = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FriendBase',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('Version $version', style: muted),
                const SizedBox(height: 4),
                Text('Made by $_author', style: muted),
              ],
            ),
          ),
          gap,
          SectionCard(
            title: 'Your data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Everything stays on this phone. Each friend is a plain '
                  'Markdown file (friends/<name>/friend.md) with their images '
                  'next to it, readable in Obsidian or any text editor.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                Text('$count friend${count == 1 ? '' : 's'}'),
                const SizedBox(height: 12),
                Text('Folder', style: theme.textTheme.bodySmall),
                SelectableText(repo.storage.root.path, style: muted),
                if (isIOS) ...[
                  const SizedBox(height: 4),
                  Text('Files app → On My iPhone → FriendBase', style: muted),
                ],
                if (problems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('${problems.length} file(s) could not be read:'),
                  for (final p in problems)
                    Text('· ${p.folder}: ${p.message}', style: muted),
                ],
              ],
            ),
          ),
          gap,
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: 'Licences',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'FriendBase',
                    applicationVersion: version,
                    applicationLegalese: _legalese,
                  ),
                ),
                _LinkTile(
                  icon: Icons.code_rounded,
                  title: 'Source code',
                  external: true,
                  onTap: () => launchUrl(
                    Uri.parse(_repoUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.external = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(
        external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

/// The privacy policy as a readable page.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Effective $kPrivacyEffectiveDate',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          for (final (heading, body) in kPrivacySections) ...[
            const SizedBox(height: 20),
            Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(height: 1.45)),
          ],
        ],
      ),
    );
  }
}
