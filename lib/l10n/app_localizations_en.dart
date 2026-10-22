// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FriendBase';

  @override
  String get back => 'Back';

  @override
  String get options => 'Options';

  @override
  String get addFriend => 'Add friend';

  @override
  String get search => 'Search';

  @override
  String filesUnreadable(int count, String names) {
    return '$count file(s) could not be read: $names';
  }

  @override
  String somethingWentWrong(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String daysShort(int days) {
    return '${days}d';
  }

  @override
  String inDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in ${days}d',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get noFriendsTitle => 'No friends yet';

  @override
  String get noFriendsBody => 'Tap the button below to add someone.';

  @override
  String lastCallAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'Yesterday',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Facts, Favourites, etc..';

  @override
  String get edit => 'Edit';

  @override
  String birthdayIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String turnsAge(int age) {
    return 'turns $age';
  }

  @override
  String get lastCall => 'Last call';

  @override
  String get callHint => 'Tap the dot after a call · hold it to pick a date';

  @override
  String recentCalls(String dates) {
    return 'Recent: $dates';
  }

  @override
  String callLogged(String when) {
    return 'Call logged: $when';
  }

  @override
  String get undo => 'Undo';

  @override
  String get images => 'Images';

  @override
  String get skip => 'Skip';

  @override
  String couldNotAddImage(String error) {
    return 'Could not add image: $error';
  }

  @override
  String get addImage => 'Add image';

  @override
  String get calledToday => 'Called today';

  @override
  String get calledTodayHint => 'Hold to log an earlier call';

  @override
  String get noImages => 'No images';

  @override
  String get imagePathNotAllowed => 'This image path is not allowed';

  @override
  String missingFile(String file) {
    return 'Missing file: $file';
  }

  @override
  String get previousImage => 'Previous image';

  @override
  String get nextImage => 'Next image';

  @override
  String get deleteImage => 'Delete image';

  @override
  String get deleteImageTitle => 'Delete this image?';

  @override
  String get deleteImageBody =>
      'The file is removed from the friend\'s folder.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get tapToAddContext => 'Tap to add context';

  @override
  String get captionTitle => 'What is this image about?';

  @override
  String get captionHint => 'e.g. the cake she loved at her 30th';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String couldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String deleteFriendTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteFriendBody =>
      'Their file, notes and images will be removed.';

  @override
  String get newFriend => 'New friend';

  @override
  String get editFriend => 'Edit friend';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get nickname => 'Nickname';

  @override
  String get phoneNumbers => 'Phone numbers';

  @override
  String get onePerLine => 'One per line';

  @override
  String get emails => 'Emails';

  @override
  String get address => 'Address';

  @override
  String get callEvery => 'Call every … days';

  @override
  String callEveryHelper(int days) {
    return 'Leave empty for the default ($days)';
  }

  @override
  String get wholeNumber => 'A whole number, 1 or more';

  @override
  String get deleteFriend => 'Delete friend';

  @override
  String get birthday => 'Birthday';

  @override
  String get clearBirthday => 'Clear birthday';

  @override
  String get profilePicture => 'Profile picture';

  @override
  String get removePicture => 'Remove picture';

  @override
  String couldNotPickPicture(String error) {
    return 'Could not pick a picture: $error';
  }

  @override
  String get clear => 'Clear';

  @override
  String get done => 'Done';

  @override
  String yearUnknownHint(String dash) {
    return 'Leave the year at $dash if you don\'t know it.';
  }

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeMint => 'Mint';

  @override
  String get themeSky => 'Sky';

  @override
  String get themeLavender => 'Lavender';

  @override
  String get display => 'Display';

  @override
  String get font => 'Font';

  @override
  String get fontSystem => 'System';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontReadable => 'Readable';

  @override
  String get fontMono => 'Mono';

  @override
  String get textSize => 'Text size';

  @override
  String get dateFormat => 'Date format';

  @override
  String get compactList => 'Compact list';

  @override
  String get compactListHint => 'Smaller rows, fewer details';

  @override
  String get list => 'List';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortCallDue => 'Call due';

  @override
  String get sortName => 'Name';

  @override
  String get showInList => 'Show in list';

  @override
  String get nothing => 'Nothing';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get aboutApp => 'About FriendBase';

  @override
  String get aboutAppHint => 'Version, your data, privacy, licences';

  @override
  String get reminders => 'Reminders';

  @override
  String get birthdaysAhead => 'Birthdays ahead';

  @override
  String get birthdaysAheadHint => 'A few days before, to plan something';

  @override
  String get daysBefore => 'Days before';

  @override
  String get birthdaysOnDay => 'Birthdays on the day';

  @override
  String get birthdaysOnDayHint => 'A nudge to send your wishes';

  @override
  String get overdueCalls => 'Overdue calls';

  @override
  String get overdueCallsHint => 'When a friend passes their call interval';

  @override
  String get timeOfDay => 'Time of day';

  @override
  String get notificationsOff =>
      'Notifications are off for FriendBase. You can allow them in your phone settings.';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String madeBy(String author) {
    return 'Made by $author';
  }

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataBody =>
      'Everything stays on this phone. Each friend is a plain Markdown file (friends/<name>/friend.md) with their images next to it, readable in Obsidian or any text editor.';

  @override
  String friendCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
    );
    return '$_temp0';
  }

  @override
  String get folder => 'Folder';

  @override
  String get filesAppHint => 'Files app → On My iPhone → FriendBase';

  @override
  String filesUnreadableList(int count) {
    return '$count file(s) could not be read:';
  }

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get licences => 'Licences';

  @override
  String get sourceCode => 'Source code';

  @override
  String legalese(String author) {
    return '© 2026 $author\nReleased under the MIT License.';
  }

  @override
  String effectiveFrom(String date) {
    return 'Effective $date';
  }

  @override
  String reminderBirthdayTitle(String name) {
    return '$name\'s birthday';
  }

  @override
  String get reminderToday => 'Today';

  @override
  String get reminderTomorrow => 'Tomorrow';

  @override
  String reminderInDays(int days, String date) {
    return 'In $days days ($date)';
  }

  @override
  String reminderTurns(int age) {
    return ' — turns $age';
  }

  @override
  String reminderCallTitle(String name) {
    return 'Time to call $name';
  }

  @override
  String reminderCallBody(int days, int interval) {
    return '${days}d since your last call (every ${interval}d)';
  }
}
