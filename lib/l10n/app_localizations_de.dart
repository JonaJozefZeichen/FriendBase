// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FriendBase';

  @override
  String get back => 'Zurück';

  @override
  String get options => 'Optionen';

  @override
  String get addFriend => 'Person hinzufügen';

  @override
  String get search => 'Suchen';

  @override
  String filesUnreadable(int count, String names) {
    return '$count Datei(en) konnten nicht gelesen werden: $names';
  }

  @override
  String somethingWentWrong(String error) {
    return 'Etwas ist schiefgelaufen: $error';
  }

  @override
  String get overdue => 'Überfällig';

  @override
  String daysShort(int days) {
    return '$days T';
  }

  @override
  String inDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days T',
      one: 'morgen',
      zero: 'heute',
    );
    return '$_temp0';
  }

  @override
  String get noFriendsTitle => 'Noch niemand hier';

  @override
  String get noFriendsBody =>
      'Tippe unten auf den Button, um jemanden hinzuzufügen.';

  @override
  String lastCallAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'vor $days Tagen',
      one: 'Gestern',
      zero: 'Heute',
    );
    return '$_temp0';
  }

  @override
  String get notes => 'Notizen';

  @override
  String get notesHint => 'Fakten, Lieblingsdinge usw.';

  @override
  String get edit => 'Bearbeiten';

  @override
  String birthdayIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days Tagen',
      one: 'morgen',
      zero: 'heute',
    );
    return '$_temp0';
  }

  @override
  String turnsAge(int age) {
    return 'wird $age';
  }

  @override
  String get lastCall => 'Letzter Anruf';

  @override
  String get callHint =>
      'Nach dem Gespräch antippen · gedrückt halten für ein anderes Datum';

  @override
  String recentCalls(String dates) {
    return 'Zuletzt: $dates';
  }

  @override
  String callLogged(String when) {
    return 'Anruf eingetragen: $when';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get images => 'Bilder';

  @override
  String get skip => 'Überspringen';

  @override
  String couldNotAddImage(String error) {
    return 'Bild konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get calledToday => 'Heute angerufen';

  @override
  String get calledTodayHint =>
      'Gedrückt halten, um einen früheren Anruf einzutragen';

  @override
  String get noImages => 'Keine Bilder';

  @override
  String get imagePathNotAllowed => 'Dieser Bildpfad ist nicht erlaubt';

  @override
  String missingFile(String file) {
    return 'Datei fehlt: $file';
  }

  @override
  String get previousImage => 'Vorheriges Bild';

  @override
  String get nextImage => 'Nächstes Bild';

  @override
  String get deleteImage => 'Bild löschen';

  @override
  String get deleteImageTitle => 'Dieses Bild löschen?';

  @override
  String get deleteImageBody =>
      'Die Datei wird aus dem Ordner der Person entfernt.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get tapToAddContext => 'Tippen, um Kontext hinzuzufügen';

  @override
  String get captionTitle => 'Worum geht es auf diesem Bild?';

  @override
  String get captionHint => 'z. B. der Kuchen, den sie an ihrem 30. so mochte';

  @override
  String get chooseFromGallery => 'Aus der Galerie wählen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String couldNotSave(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String deleteFriendTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get deleteFriendBody => 'Datei, Notizen und Bilder werden entfernt.';

  @override
  String get newFriend => 'Neue Person';

  @override
  String get editFriend => 'Person bearbeiten';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Bitte gib einen Namen ein';

  @override
  String get nickname => 'Spitzname';

  @override
  String get phoneNumbers => 'Telefonnummern';

  @override
  String get onePerLine => 'Eine pro Zeile';

  @override
  String get emails => 'E-Mail-Adressen';

  @override
  String get address => 'Adresse';

  @override
  String get callEvery => 'Anrufen alle … Tage';

  @override
  String callEveryHelper(int days) {
    return 'Leer lassen für den Standard ($days)';
  }

  @override
  String get wholeNumber => 'Eine ganze Zahl ab 1';

  @override
  String get deleteFriend => 'Person löschen';

  @override
  String get birthday => 'Geburtstag';

  @override
  String get clearBirthday => 'Geburtstag entfernen';

  @override
  String get profilePicture => 'Profilbild';

  @override
  String get removePicture => 'Bild entfernen';

  @override
  String couldNotPickPicture(String error) {
    return 'Bild konnte nicht ausgewählt werden: $error';
  }

  @override
  String get clear => 'Entfernen';

  @override
  String get done => 'Fertig';

  @override
  String yearUnknownHint(String dash) {
    return 'Lass das Jahr auf $dash, wenn du es nicht weißt.';
  }

  @override
  String get display => 'Anzeige';

  @override
  String get font => 'Schrift';

  @override
  String get fontSystem => 'System';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontReadable => 'Lesbar';

  @override
  String get fontMono => 'Mono';

  @override
  String get textSize => 'Textgröße';

  @override
  String get dateFormat => 'Datumsformat';

  @override
  String get compactList => 'Kompakte Liste';

  @override
  String get compactListHint => 'Kleinere Zeilen, weniger Details';

  @override
  String get list => 'Liste';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortCallDue => 'Anruf fällig';

  @override
  String get sortName => 'Name';

  @override
  String get showInList => 'In der Liste zeigen';

  @override
  String get nothing => 'Nichts';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get aboutApp => 'Über FriendBase';

  @override
  String get aboutAppHint => 'Version, deine Daten, Datenschutz, Lizenzen';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get birthdaysAhead => 'Geburtstage vorab';

  @override
  String get birthdaysAheadHint => 'Ein paar Tage vorher, um etwas zu planen';

  @override
  String get daysBefore => 'Tage vorher';

  @override
  String get birthdaysOnDay => 'Geburtstage am Tag';

  @override
  String get birthdaysOnDayHint => 'Ein Anstoß zum Gratulieren';

  @override
  String get overdueCalls => 'Überfällige Anrufe';

  @override
  String get overdueCallsHint => 'Wenn der Anrufabstand überschritten ist';

  @override
  String get timeOfDay => 'Uhrzeit';

  @override
  String get notificationsOff =>
      'Mitteilungen sind für FriendBase ausgeschaltet. Du kannst sie in den Einstellungen deines Telefons erlauben.';

  @override
  String get about => 'Über';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String madeBy(String author) {
    return 'Von $author';
  }

  @override
  String get yourData => 'Deine Daten';

  @override
  String get yourDataBody =>
      'Alles bleibt auf diesem Telefon. Jede Person ist eine einfache Markdown-Datei (friends/<name>/friend.md) mit ihren Bildern daneben, lesbar in Obsidian oder jedem Texteditor.';

  @override
  String friendCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String get folder => 'Ordner';

  @override
  String get filesAppHint => 'Dateien-App → Auf meinem iPhone → FriendBase';

  @override
  String filesUnreadableList(int count) {
    return '$count Datei(en) konnten nicht gelesen werden:';
  }

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get licences => 'Lizenzen';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String legalese(String author) {
    return '© 2026 $author\nVeröffentlicht unter der MIT-Lizenz.';
  }

  @override
  String effectiveFrom(String date) {
    return 'Gültig ab $date';
  }

  @override
  String reminderBirthdayTitle(String name) {
    return 'Geburtstag von $name';
  }

  @override
  String get reminderToday => 'Heute';

  @override
  String get reminderTomorrow => 'Morgen';

  @override
  String reminderInDays(int days, String date) {
    return 'In $days Tagen ($date)';
  }

  @override
  String reminderTurns(int age) {
    return ' — wird $age';
  }

  @override
  String reminderCallTitle(String name) {
    return 'Zeit, $name anzurufen';
  }

  @override
  String reminderCallBody(int days, int interval) {
    return '$days Tage seit dem letzten Anruf (alle $interval Tage)';
  }

  @override
  String get paper => 'Papier';

  @override
  String get paperSystem => 'System';

  @override
  String get paperCream => 'Creme';

  @override
  String get paperKraft => 'Kraft';

  @override
  String get paperBlue => 'Blau';

  @override
  String get paperInk => 'Tinte';

  @override
  String get alreadyLoggedToday => 'Heute ist schon ein Anruf eingetragen';

  @override
  String alreadyLoggedOn(String date) {
    return 'Am $date ist schon ein Anruf eingetragen';
  }

  @override
  String get close => 'Schließen';
}
