/// FriendBase's privacy policy, shown in About → Privacy policy.
///
/// `PRIVACY.md` in the repository holds the same text (for app stores and
/// GitHub); `test/features/privacy_policy_test.dart` keeps them in sync.
library;

const kPrivacyEffectiveDate = '22 October 2026';

const kPrivacySections = <(String, String)>[
  (
    'In short',
    'FriendBase does not collect, send or sell any data. It has no account, '
        'no analytics, no ads and no servers. Everything you enter stays on '
        'your phone.',
  ),
  (
    'What the app stores',
    'The details you enter about your friends (names, birthdays, contact '
        'details, notes, call dates), the pictures you add, and your app '
        'settings. Each friend is saved as a plain Markdown file with their '
        'pictures next to it, in the FriendBase folder inside the app\'s own '
        'storage on your phone.',
  ),
  (
    'Where it goes',
    'Nowhere, unless you move it. FriendBase never connects to the internet. '
        'Your phone may include the app\'s folder in its own backups (iCloud '
        'Backup on iPhone, Google backup on Android) depending on your phone '
        'settings; those backups are handled by Apple or Google under their '
        'terms. On iPhone the folder is also visible in the Files app, so you '
        'can copy it yourself.',
  ),
  (
    'Permissions',
    'Photos and camera: only when you add a picture, and only the picture you '
        'choose is copied into FriendBase. Notifications: only if you turn on '
        'reminders; they are scheduled on your phone and never sent from a '
        'server. Tapping a phone number or email address hands it to your '
        'phone or mail app.',
  ),
  (
    'About your friends\' data',
    'FriendBase holds information about other people. Please keep it to what '
        'you would be comfortable with them knowing, and protect your phone '
        'with a passcode.',
  ),
  (
    'Deleting your data',
    'Deleting a friend removes their file and pictures. Uninstalling the app '
        'removes everything it stored, apart from copies in your own backups.',
  ),
  (
    'Children',
    'FriendBase is not directed at children and does not knowingly collect '
        'anything from anyone.',
  ),
  (
    'Changes',
    'If this policy changes, the new version ships with an app update and '
        'the date at the top changes.',
  ),
  (
    'Contact',
    'FriendBase is made by Jona Jožef Zeichen. Questions are welcome as an '
        'issue at github.com/JonaJozefZeichen/FriendBase.',
  ),
];
