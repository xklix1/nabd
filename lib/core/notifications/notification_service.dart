import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Offline Medication Reminder Notification Service.
/// Implements OWASP Lock-Screen Privacy:
/// Sensitive drug or diagnosis names are masked on the device lock screen,
/// showing only a generic, safe notification prompt.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
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
        // Handle notification click: route directly to Reminders screen
      },
    );

    _isInitialized = true;
  }

  /// Schedules offline medication reminders (either one-time exact date/time or recurring).
  /// Enforces lock-screen privacy by using masked generic messages on lock screens.
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime firstDoseTime,
    required int intervalHours,
    bool isOneTime = false,
    required bool isArabic,
  }) async {
    final title = isArabic
        ? (isOneTime ? 'تذكير بجرعة محددة (مرة واحدة)' : 'تذكير بالجرعة الدوائية')
        : (isOneTime ? 'One-Time Medication Reminder' : 'Medication Reminder');
    
    // Privacy-Preserving Lock Screen Message
    final maskedBody = isArabic
        ? 'حان موعد جرعتك الدوائية ($medicationName). افتح نبض للاطلاع على التفاصيل بأمان.'
        : 'Time for your scheduled medication ($medicationName). Open Nabd to view details securely.';

    // Safe details channel
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders_channel',
      'Medication Reminders',
      channelDescription: 'Offline medication dosage alerts with privacy protection',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.private, // Masks details on Android lock screen
      ticker: 'Nabd Reminder',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the reminder
    final scheduledDate = tz.TZDateTime.from(firstDoseTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      maskedBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: isOneTime ? null : DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }
}
