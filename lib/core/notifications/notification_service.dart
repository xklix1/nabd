import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'alarm_audio_service.dart';

/// Offline Medication Reminder & High-Priority Medical Alarm Service.
/// Implements:
/// 1. Insistent Alarm ringing with custom sound ('medication_alarm.wav')
/// 2. STREAM_ALARM direct audio playback for elderly and hearing-impaired users
/// 3. Deep vibration pattern tailored for high accessibility
/// 4. Lock-screen privacy and full-screen intent wake
/// 5. Direct Dose Taken & Snooze actions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String alarmChannelId = 'nabd_medication_alarm_v4';
  static const String alarmChannelName = 'منبه الأدوية عالي الأولوية | Medical Alarm';
  static const String alarmChannelDesc =
      'منبه عالي الصوت واهتزاز متواصل لتنبيه كبار السن وضعاف السمع بمواعيد الدواء';

  Future<void> initialize({
    void Function(NotificationResponse response)? onNotificationTapped,
  }) async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'action_taken' || response.actionId == 'action_snooze') {
          AlarmAudioService.stopAlarm();
        } else {
          // User opened the notification: start insistent alarm audio
          AlarmAudioService.startAlarm();
        }
        if (onNotificationTapped != null) {
          onNotificationTapped(response);
        }
      },
    );

    // Create the dedicated Alarm Notification Channel explicitly on Android
    final androidNotificationPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      // Explicitly request notification and alarm permissions on Android 13+ (API 33-36)
      await androidNotificationPlugin.requestNotificationsPermission();
      await androidNotificationPlugin.requestExactAlarmsPermission();

      // Delete previous channel version if needed to force Android to apply new sound & importance
      await androidNotificationPlugin.deleteNotificationChannel('nabd_medication_alarm_v3');
      await androidNotificationPlugin.deleteNotificationChannel(alarmChannelId);

      await androidNotificationPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('medication_alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800, 400, 1200]),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }

    _isInitialized = true;
  }

  /// Builds notification details configured as a medical alarm
  NotificationDetails _buildAlarmNotificationDetails({required bool isArabic}) {
    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('medication_alarm'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800, 400, 1200]),
      // FLAG_INSISTENT (4): continues playing audio and vibrating until dismissed
      additionalFlags: Int32List.fromList([4]),
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ticker: 'Nabd Medication Alarm',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          isArabic ? '✅ تم تناول الدواء' : '✅ Taken Dose',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_snooze',
          isArabic ? '⏰ غفوة 10 دقائق' : '⏰ Snooze 10m',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'medication_alarm.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Schedules medication reminder as an audible, insistent medical alarm
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime firstDoseTime,
    required int intervalHours,
    bool isOneTime = false,
    required bool isArabic,
    String doseDescription = '',
  }) async {
    final title = isArabic
        ? '⏰ منبه موعد الدواء: $medicationName'
        : '⏰ Medication Alarm: $medicationName';

    final doseText = doseDescription.isNotEmpty ? ' ($doseDescription)' : '';
    final body = isArabic
        ? 'حان الآن موعد تناول دواء $medicationName$doseText. يرجى أخذ الجرعة للحفاظ على سلامتك.'
        : 'Time to take your dose of $medicationName$doseText. Please take it now.';

    final notificationDetails = _buildAlarmNotificationDetails(isArabic: isArabic);

    // If first dose time is in the past (e.g. earlier today), shift by interval or start now
    var targetDate = firstDoseTime;
    if (targetDate.isBefore(DateTime.now())) {
      if (isOneTime) {
        // If scheduled in the past for one-time, schedule in 1 minute
        targetDate = DateTime.now().add(const Duration(minutes: 1));
      } else {
        while (targetDate.isBefore(DateTime.now())) {
          targetDate = targetDate.add(Duration(hours: intervalHours > 0 ? intervalHours : 24));
        }
      }
    }

    final scheduledDate = tz.TZDateTime.from(targetDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: isOneTime ? null : DateTimeComponents.time,
      payload: '$id|$medicationName|$doseDescription',
    );
  }

  /// Immediately triggers the live medical alarm with dedicated hardware STREAM_ALARM audio
  Future<void> triggerImmediateAlarm({
    int id = 9999,
    required String medicationName,
    String doseDescription = '',
    required bool isArabic,
  }) async {
    // 1. Start dedicated native audio on STREAM_ALARM (looping & vibrating)
    await AlarmAudioService.startAlarm();

    // 2. Display high-priority insistent alarm notification
    final title = isArabic
        ? '🔔 تجربة منبه الدواء الحي: $medicationName'
        : '🔔 Live Medication Alarm: $medicationName';

    final doseText = doseDescription.isNotEmpty ? ' ($doseDescription)' : '';
    final body = isArabic
        ? 'منبه عالي الصوت واهتزاز مستمر مخصص لكبار السن لتأكيد موعد $medicationName$doseText'
        : 'High-priority insistent alarm and continuous vibration for $medicationName$doseText';

    final notificationDetails = _buildAlarmNotificationDetails(isArabic: isArabic);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: '$id|$medicationName|$doseDescription',
    );
  }

  /// Snoozes an alarm for [minutes] and stops active sound
  Future<void> snoozeReminder({
    required int id,
    required String medicationName,
    String doseDescription = '',
    required bool isArabic,
    int minutes = 10,
  }) async {
    await AlarmAudioService.stopAlarm();
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    await scheduleMedicationReminder(
      id: id,
      medicationName: medicationName,
      firstDoseTime: snoozeTime,
      intervalHours: 0,
      isOneTime: true,
      isArabic: isArabic,
      doseDescription: doseDescription,
    );
  }

  Future<void> cancelReminder(int id) async {
    await AlarmAudioService.stopAlarm();
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await AlarmAudioService.stopAlarm();
    await _notificationsPlugin.cancelAll();
  }
}
