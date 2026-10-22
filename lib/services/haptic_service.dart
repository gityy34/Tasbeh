import 'package:flutter/services.dart';

abstract interface class TargetHapticService {
  Future<void> targetCompleted();
}

class PlatformTargetHapticService implements TargetHapticService {
  const PlatformTargetHapticService();

  static const MethodChannel _channel =
      MethodChannel('com.gityy34.tasbeh/haptics');

  @override
  Future<void> targetCompleted() async {
    try {
      // Use the Android vibrator directly so the user receives a real,
      // short completion signal even when system haptic feedback is subtle.
      await _channel.invokeMethod<void>('targetCompleted');
    } on MissingPluginException {
      // Keep previews, tests, and non-Android platforms functional.
      await HapticFeedback.mediumImpact();
    } on PlatformException {
      // Fall back gracefully if the native channel is temporarily unavailable.
      await HapticFeedback.mediumImpact();
    }
  }
}
