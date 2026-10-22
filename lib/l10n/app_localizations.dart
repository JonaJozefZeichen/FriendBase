import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FriendBase'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filesUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) could not be read: {names}'**
  String filesUnreadable(int count, String names);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrong(String error);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysShort(int days);

  /// No description provided for @inDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{tomorrow} other{in {days}d}}'**
  String inDaysShort(int days);

  /// No description provided for @noFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsTitle;

  /// No description provided for @noFriendsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add someone.'**
  String get noFriendsBody;

  /// No description provided for @lastCallAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{Yesterday} other{{days} days ago}}'**
  String lastCallAgo(int days);

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Facts, Favourites, etc..'**
  String get notesHint;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @birthdayIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{tomorrow} other{in {days} days}}'**
  String birthdayIn(int days);

  /// No description provided for @turnsAge.
  ///
  /// In en, this message translates to:
  /// **'turns {age}'**
  String turnsAge(int age);

  /// No description provided for @lastCall.
  ///
  /// In en, this message translates to:
  /// **'Last call'**
  String get lastCall;

  /// No description provided for @callHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the dot after a call · hold it to pick a date'**
  String get callHint;

  /// No description provided for @recentCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent: {dates}'**
  String recentCalls(String dates);

  /// No description provided for @callLogged.
  ///
  /// In en, this message translates to:
  /// **'Call logged: {when}'**
  String callLogged(String when);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @couldNotAddImage.
  ///
  /// In en, this message translates to:
  /// **'Could not add image: {error}'**
  String couldNotAddImage(String error);

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @calledToday.
  ///
  /// In en, this message translates to:
  /// **'Called today'**
  String get calledToday;

  /// No description provided for @calledTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Hold to log an earlier call'**
  String get calledTodayHint;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get noImages;

  /// No description provided for @imagePathNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This image path is not allowed'**
  String get imagePathNotAllowed;

  /// No description provided for @missingFile.
  ///
  /// In en, this message translates to:
  /// **'Missing file: {file}'**
  String missingFile(String file);

  /// No description provided for @previousImage.
  ///
  /// In en, this message translates to:
  /// **'Previous image'**
  String get previousImage;

  /// No description provided for @nextImage.
  ///
  /// In en, this message translates to:
  /// **'Next image'**
  String get nextImage;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get deleteImage;

  /// No description provided for @deleteImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this image?'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageBody.
  ///
  /// In en, this message translates to:
  /// **'The file is removed from the friend\'s folder.'**
  String get deleteImageBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @tapToAddContext.
  ///
  /// In en, this message translates to:
  /// **'Tap to add context'**
  String get tapToAddContext;

  /// No description provided for @captionTitle.
  ///
  /// In en, this message translates to:
  /// **'What is this image about?'**
  String get captionTitle;

  /// No description provided for @captionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. the cake she loved at her 30th'**
  String get captionHint;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSave(String error);

  /// No description provided for @deleteFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFriendTitle(String name);

  /// No description provided for @deleteFriendBody.
  ///
  /// In en, this message translates to:
  /// **'Their file, notes and images will be removed.'**
  String get deleteFriendBody;

  /// No description provided for @newFriend.
  ///
  /// In en, this message translates to:
  /// **'New friend'**
  String get newFriend;

  /// No description provided for @editFriend.
  ///
  /// In en, this message translates to:
  /// **'Edit friend'**
  String get editFriend;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequired;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @phoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers'**
  String get phoneNumbers;

  /// No description provided for @onePerLine.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get onePerLine;

  /// No description provided for @emails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get emails;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @callEvery.
  ///
  /// In en, this message translates to:
  /// **'Call every … days'**
  String get callEvery;

  /// No description provided for @callEveryHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the default ({days})'**
  String callEveryHelper(int days);

  /// No description provided for @wholeNumber.
  ///
  /// In en, this message translates to:
  /// **'A whole number, 1 or more'**
  String get wholeNumber;

  /// No description provided for @deleteFriend.
  ///
  /// In en, this message translates to:
  /// **'Delete friend'**
  String get deleteFriend;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @clearBirthday.
  ///
  /// In en, this message translates to:
  /// **'Clear birthday'**
  String get clearBirthday;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePicture;

  /// No description provided for @removePicture.
  ///
  /// In en, this message translates to:
  /// **'Remove picture'**
  String get removePicture;

  /// No description provided for @couldNotPickPicture.
  ///
  /// In en, this message translates to:
  /// **'Could not pick a picture: {error}'**
  String couldNotPickPicture(String error);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yearUnknownHint.
  ///
  /// In en, this message translates to:
  /// **'Leave the year at {dash} if you don\'t know it.'**
  String yearUnknownHint(String dash);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get themeRose;

  /// No description provided for @themeMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get themeMint;

  /// No description provided for @themeSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get themeSky;

  /// No description provided for @themeLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get themeLavender;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get fontSystem;

  /// No description provided for @fontSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// No description provided for @fontReadable.
  ///
  /// In en, this message translates to:
  /// **'Readable'**
  String get fontReadable;

  /// No description provided for @fontMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get fontMono;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormat;

  /// No description provided for @compactList.
  ///
  /// In en, this message translates to:
  /// **'Compact list'**
  String get compactList;

  /// No description provided for @compactListHint.
  ///
  /// In en, this message translates to:
  /// **'Smaller rows, fewer details'**
  String get compactListHint;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortCallDue.
  ///
  /// In en, this message translates to:
  /// **'Call due'**
  String get sortCallDue;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @showInList.
  ///
  /// In en, this message translates to:
  /// **'Show in list'**
  String get showInList;

  /// No description provided for @nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get nothing;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About FriendBase'**
  String get aboutApp;

  /// No description provided for @aboutAppHint.
  ///
  /// In en, this message translates to:
  /// **'Version, your data, privacy, licences'**
  String get aboutAppHint;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @birthdaysAhead.
  ///
  /// In en, this message translates to:
  /// **'Birthdays ahead'**
  String get birthdaysAhead;

  /// No description provided for @birthdaysAheadHint.
  ///
  /// In en, this message translates to:
  /// **'A few days before, to plan something'**
  String get birthdaysAheadHint;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get daysBefore;

  /// No description provided for @birthdaysOnDay.
  ///
  /// In en, this message translates to:
  /// **'Birthdays on the day'**
  String get birthdaysOnDay;

  /// No description provided for @birthdaysOnDayHint.
  ///
  /// In en, this message translates to:
  /// **'A nudge to send your wishes'**
  String get birthdaysOnDayHint;

  /// No description provided for @overdueCalls.
  ///
  /// In en, this message translates to:
  /// **'Overdue calls'**
  String get overdueCalls;

  /// No description provided for @overdueCallsHint.
  ///
  /// In en, this message translates to:
  /// **'When a friend passes their call interval'**
  String get overdueCallsHint;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get timeOfDay;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for FriendBase. You can allow them in your phone settings.'**
  String get notificationsOff;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @madeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by {author}'**
  String madeBy(String author);

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone. Each friend is a plain Markdown file (friends/<name>/friend.md) with their images next to it, readable in Obsidian or any text editor.'**
  String get yourDataBody;

  /// No description provided for @friendCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend} other{{count} friends}}'**
  String friendCount(int count);

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @filesAppHint.
  ///
  /// In en, this message translates to:
  /// **'Files app → On My iPhone → FriendBase'**
  String get filesAppHint;

  /// No description provided for @filesUnreadableList.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) could not be read:'**
  String filesUnreadableList(int count);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licences;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @legalese.
  ///
  /// In en, this message translates to:
  /// **'© 2026 {author}\nReleased under the MIT License.'**
  String legalese(String author);

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective {date}'**
  String effectiveFrom(String date);

  /// No description provided for @reminderBirthdayTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s birthday'**
  String reminderBirthdayTitle(String name);

  /// No description provided for @reminderToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reminderToday;

  /// No description provided for @reminderTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get reminderTomorrow;

  /// No description provided for @reminderInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days ({date})'**
  String reminderInDays(int days, String date);

  /// No description provided for @reminderTurns.
  ///
  /// In en, this message translates to:
  /// **' — turns {age}'**
  String reminderTurns(int age);

  /// No description provided for @reminderCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to call {name}'**
  String reminderCallTitle(String name);

  /// No description provided for @reminderCallBody.
  ///
  /// In en, this message translates to:
  /// **'{days}d since your last call (every {interval}d)'**
  String reminderCallBody(int days, int interval);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
