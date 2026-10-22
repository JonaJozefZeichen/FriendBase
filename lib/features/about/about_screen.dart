import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../ui_kit/widgets.dart';
import '../../l10n/l10n.dart';
import 'privacy_policy.dart';

const _repoUrl = 'https://github.com/JonaJozefZeichen/FriendBase';
const _author = 'Jona Jožef Zeichen';

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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
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
                Text(l10n.version(version), style: muted),
                const SizedBox(height: 4),
                Text(l10n.madeBy(_author), style: muted),
              ],
            ),
          ),
          gap,
          SectionCard(
            title: l10n.yourData,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.yourDataBody, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 12),
                Text(l10n.friendCount(count)),
                const SizedBox(height: 12),
                Text(l10n.folder, style: theme.textTheme.bodySmall),
                SelectableText(repo.storage.root.path, style: muted),
                if (isIOS) ...[
                  const SizedBox(height: 4),
                  Text(l10n.filesAppHint, style: muted),
                ],
                if (problems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l10n.filesUnreadableList(problems.length)),
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
                  title: l10n.privacyPolicy,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: l10n.licences,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'FriendBase',
                    applicationVersion: version,
                    applicationLegalese: l10n.legalese(_author),
                  ),
                ),
                _LinkTile(
                  icon: Icons.code_rounded,
                  title: l10n.sourceCode,
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
    final german = Localizations.localeOf(context).languageCode == 'de';
    final sections = german ? kPrivacySectionsDe : kPrivacySections;
    final date = german ? kPrivacyEffectiveDateDe : kPrivacyEffectiveDate;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            context.l10n.effectiveFrom(date),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          for (final (heading, body) in sections) ...[
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
