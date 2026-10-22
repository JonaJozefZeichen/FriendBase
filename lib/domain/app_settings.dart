/// Colour themes. `system` follows the phone's light/dark setting.
enum AppTheme { system, light, dark, rose, mint, sky, lavender }

/// Font families. `system` is SF Pro on iOS and Roboto on Android.
enum AppFont { system, serif, readable, mono }

enum ListSort { urgency, name, birthday }

/// App language. `system` follows the phone (German if it's set to
/// German, English otherwise).
enum AppLanguage { system, en, de }

/// How dates are shown: 29.10.1994, 10/29/1994 or 1994-10-29.
enum DateStyle { european, american, iso }

/// The small line under each name in the friend list.
enum ListDetail { lastCall, birthday, none }

/// Text size steps offered in Options.
const kTextScales = {'S': 0.9, 'M': 1.0, 'L': 1.15, 'XL': 1.3};

/// Days-before choices for birthday reminders.
const kBirthdayDaysBefore = [1, 3, 7];

/// App-wide options, stored in `<vault>/.friendbase/config.json`.
class AppSettings {
  const AppSettings({
    this.theme = AppTheme.system,
    this.font = AppFont.system,
    this.textScale = 1.0,
    this.compactList = false,
    this.listDetail = ListDetail.lastCall,
    this.dateStyle = DateStyle.european,
    this.language = AppLanguage.system,
    this.sort = ListSort.urgency,
    this.remindBirthdays = false,
    this.birthdayDaysBefore = 3,
    this.remindBirthdayOnDay = false,
    this.remindOverdueCalls = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  final AppTheme theme;
  final AppFont font;

  /// Multiplies the phone's own text size.
  final double textScale;
  final bool compactList;

  final ListDetail listDetail;
  final DateStyle dateStyle;
  final AppLanguage language;
  final ListSort sort;
  final bool remindBirthdays;
  final int birthdayDaysBefore;

  /// A second birthday reminder on the day itself.
  final bool remindBirthdayOnDay;
  final bool remindOverdueCalls;

  /// Time of day reminders arrive.
  final int reminderHour;
  final int reminderMinute;

  bool get anyReminders =>
      remindBirthdays || remindBirthdayOnDay || remindOverdueCalls;

  AppSettings copyWith({
    AppTheme? theme,
    AppFont? font,
    double? textScale,
    bool? compactList,
    ListDetail? listDetail,
    DateStyle? dateStyle,
    AppLanguage? language,
    ListSort? sort,
    bool? remindBirthdays,
    int? birthdayDaysBefore,
    bool? remindBirthdayOnDay,
    bool? remindOverdueCalls,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      font: font ?? this.font,
      textScale: textScale ?? this.textScale,
      compactList: compactList ?? this.compactList,
      listDetail: listDetail ?? this.listDetail,
      dateStyle: dateStyle ?? this.dateStyle,
      language: language ?? this.language,
      sort: sort ?? this.sort,
      remindBirthdays: remindBirthdays ?? this.remindBirthdays,
      birthdayDaysBefore: birthdayDaysBefore ?? this.birthdayDaysBefore,
      remindBirthdayOnDay: remindBirthdayOnDay ?? this.remindBirthdayOnDay,
      remindOverdueCalls: remindOverdueCalls ?? this.remindOverdueCalls,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  String get reminderTimeLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:'
      '${reminderMinute.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
    'theme': theme.name,
    'font': font.name,
    'text_scale': textScale,
    'compact_list': compactList,
    'list_detail': listDetail.name,
    'date_style': dateStyle.name,
    'language': language.name,
    'sort': sort.name,
    'remind_birthdays': remindBirthdays,
    'birthday_days_before': birthdayDaysBefore,
    'remind_birthday_on_day': remindBirthdayOnDay,
    'remind_overdue_calls': remindOverdueCalls,
    'reminder_time': reminderTimeLabel,
  };

  /// Unknown or missing values fall back to defaults, so older and
  /// hand-edited config files always load.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    const d = AppSettings();
    T pick<T>(String key, T fallback) {
      final v = json[key];
      return v is T ? v : fallback;
    }

    final scale = json['text_scale'];
    final days = pick<int>('birthday_days_before', d.birthdayDaysBefore);
    final time = RegExp(r'^(\d{1,2}):(\d{2})$')
        .firstMatch(pick<String>('reminder_time', ''));
    final hour = time == null ? null : int.parse(time[1]!);
    final minute = time == null ? null : int.parse(time[2]!);
    final validTime =
        hour != null && minute != null && hour < 24 && minute < 60;

    return AppSettings(
      theme: AppTheme.values.asNameMap()[json['theme']] ?? d.theme,
      font: AppFont.values.asNameMap()[json['font']] ?? d.font,
      textScale: scale is num && kTextScales.containsValue(scale.toDouble())
          ? scale.toDouble()
          : d.textScale,
      compactList: pick('compact_list', d.compactList),
      listDetail:
          ListDetail.values.asNameMap()[json['list_detail']] ?? d.listDetail,
      dateStyle:
          DateStyle.values.asNameMap()[json['date_style']] ?? d.dateStyle,
      language: AppLanguage.values.asNameMap()[json['language']] ?? d.language,
      sort: ListSort.values.asNameMap()[json['sort']] ?? d.sort,
      remindBirthdays: pick('remind_birthdays', d.remindBirthdays),
      birthdayDaysBefore: kBirthdayDaysBefore.contains(days)
          ? days
          : d.birthdayDaysBefore,
      remindBirthdayOnDay: pick(
        'remind_birthday_on_day',
        d.remindBirthdayOnDay,
      ),
      remindOverdueCalls: pick('remind_overdue_calls', d.remindOverdueCalls),
      reminderHour: validTime ? hour : d.reminderHour,
      reminderMinute: validTime ? minute : d.reminderMinute,
    );
  }
}
