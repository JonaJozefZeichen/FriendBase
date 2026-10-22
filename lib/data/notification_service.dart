import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// Schedules local notifications. Nothing leaves the device.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Upcoming birthdays and friends to call',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      // Unknown zone name: tz.local stays UTC, reminders may be off by the
      // UTC offset, but still arrive.
      debugPrint('timezone lookup failed: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        // A one-colour silhouette, as Android expects for the status bar.
        android: AndroidInitializationSettings('@drawable/ic_stat_friendbase'),
        // Permission is asked when a reminder is switched on, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<void> _ensureReady() => _ready ??= _init();

  /// Asks the OS for permission. True if notifications may be shown.
  Future<bool> requestPermission() async {
    await _ensureReady();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Cancels every pending reminder and schedules [reminders] instead.
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _ensureReady();
    await _plugin.cancelAll();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.when, tz.local),
        notificationDetails: _details,
        // Inexact: no exact-alarm permission needed, may arrive a few
        // minutes late, which is fine for a reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
