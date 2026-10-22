# FriendBase
FriendBase is a local-only, offline phone app (iOS + Android) to keep track of friends: names, birthdays, addresses, phone numbers, free-form notes (food, allergies, flowers, movies, interests…), pictures, and an "I called them" button that tracks how long it has been since the last meaningful call.

## Features
- Friend list sorted by who needs a call, by name or by next birthday; show last call, birthday or nothing per row
- Friend view with profile picture, contact details, birthday, one-tap call logging (hold for an earlier date) and notes
- Reference images with captions, full-screen viewer
- Reminders for upcoming birthdays (days ahead and/or on the day) and overdue calls — scheduled locally
- "Ledger" design: dot-grid paper, frosted glass cards, serif names with monospace data; four papers (Cream, Kraft, Blue, Ink) plus System, five font choices, text size, date format (European / American / ISO)
- English and German
- No account, no network, no analytics — see the [privacy policy](PRIVACY.md) ([Deutsch](PRIVACY.de.md))

## How data is stored
Like an Obsidian vault: every friend is a plain Markdown file you own.

```
FriendBase/friends/<name>/friend.md   ← YAML frontmatter (birthday, phones, call log, images) + notes
FriendBase/friends/<name>/assets/     ← profile picture and images
FriendBase/.friendbase/config.json    ← app settings
```

On iOS the `FriendBase` folder is visible in the Files app under *On My iPhone → FriendBase*.

## Development
```sh
flutter pub get
flutter test        # codec, reminders, repository, settings and widget tests
flutter run
```

Code layout: `lib/domain` (model, call/birthday/reminder logic) · `lib/data` (Markdown codec, file storage, repository, notifications) · `lib/app` (theme, Riverpod providers) · `lib/features` (screens) · `lib/ui_kit` (shared widgets) · `lib/l10n` (English/German strings, `.arb` files).

## Licence
MIT © 2026 Jona Jožef Zeichen — see [LICENSE](LICENSE).
