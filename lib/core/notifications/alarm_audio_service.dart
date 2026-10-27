import 'package:flutter/services.dart';

/// Native Alarm Audio & Vibration Service.
/// Streams directly through Android's dedicated STREAM_ALARM (AudioAttributes.USAGE_ALARM).
/// This bypasses standard notification volume limitations and guarantees
/// a loud, looping alarm tone and insistent vibration tailored for elderly and hearing-impaired users.
class AlarmAudioService {
  static const MethodChannel _channel = MethodChannel('com.nabd.healthapp/alarm_audio');

  static Future<void> startAlarm() async {
    try {
      await _channel.invokeMethod('startAlarm');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to start native alarm: ${e.message}');
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to stop native alarm: ${e.message}');
    }
  }

  static Future<bool> isAlarmPlaying() async {
    try {
      final bool? playing = await _channel.invokeMethod<bool>('isAlarmPlaying');
      return playing ?? false;
    } on PlatformException {
      return false;
    }
  }
}
