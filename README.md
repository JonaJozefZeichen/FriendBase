# FriendBase
FriendBase is a local-only, offline phone app to keep track of friends: names, birthdays, addresses, phone numbers, free-form notes (food, allergies, flowers, movies, interests…), optional images, and a "I called them" button that tracks how long it has been since the last meaningful call.  

## How data is stored
Like an Obsidian vault: every friend is a plain Markdown file you own.

```
FriendBase/friends/<name>/friend.md   ← YAML frontmatter (birthday, phones, call log) + notes
FriendBase/friends/<name>/assets/     ← images (coming in a later version)
```

On iOS the `FriendBase` folder is visible in the Files app under *On My iPhone → FriendBase*.

## Development
```sh
flutter pub get
flutter test        # codec, call status, repository and widget tests
flutter run
```

Code layout: `lib/domain` (model, call/birthday logic) · `lib/data` (Markdown codec, file storage, repository) · `lib/app` (theme, Riverpod providers) · `lib/features` (list, detail, edit screens) · `lib/ui_kit` (ASCII widgets).
