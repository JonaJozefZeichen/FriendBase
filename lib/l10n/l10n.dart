import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../domain/app_settings.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// The app's strings in the current language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The locale to force for [language], or null to follow the phone.
Locale? localeFor(AppLanguage language) => switch (language) {
  AppLanguage.system => null,
  AppLanguage.en => const Locale('en'),
  AppLanguage.de => const Locale('de'),
};

/// Strings without a BuildContext (e.g. for scheduling notifications):
/// the chosen language, or the phone's if it is supported, else English.
AppLocalizations l10nFor(AppLanguage language) {
  final forced = localeFor(language);
  if (forced != null) return lookupAppLocalizations(forced);
  final phone = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == phone.languageCode,
  );
  return lookupAppLocalizations(supported ? phone : const Locale('en'));
}
