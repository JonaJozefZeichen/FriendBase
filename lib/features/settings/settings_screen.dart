import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui_kit/ascii.dart';

/// App options, opened from the `[≡]` button on the friend list.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final notifier = ref.read(settingsProvider.notifier);

    Widget option(String label, ThemeMode mode) {
      final selected = themeMode == mode;
      void onPressed() => notifier.setThemeMode(mode);
      return Expanded(
        child: selected
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(label),
              ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(60, 14, 0, 24),
                  child: Text(
                    'OPTIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                AsciiBox(
                  title: 'theme',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          option('[ LIGHT ]', ThemeMode.light),
                          const SizedBox(width: 12),
                          option('[ DARK ]', ThemeMode.dark),
                        ],
                      ),
                      if (themeMode == ThemeMode.system) ...[
                        const SizedBox(height: 8),
                        Text(
                          'following your phone until you pick one',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 8,
              top: 8,
              child: SquareButton(
                label: '<',
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
