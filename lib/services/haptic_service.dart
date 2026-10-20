import 'package:flutter/services.dart';

abstract interface class TargetHapticService {
  Future<void> targetCompleted();
}

class PlatformTargetHapticService implements TargetHapticService {
  const PlatformTargetHapticService();

  @override
  Future<void> targetCompleted() => HapticFeedback.mediumImpact();
}
