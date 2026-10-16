import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/storage_service.dart';

class TasbehController extends ChangeNotifier {
  TasbehController(this._storage);

  final StorageService _storage;
  Future<void> _writeQueue = Future<void>.value();
  bool _ready = false;
  int _count = 0;
  int? _target = 100;
  TasbehSettings _settings = const TasbehSettings();
  List<TasbehCheckpoint> _checkpoints = const [];

  bool get isReady => _ready;
  int get count => _count;
  int? get target => _target;
  TasbehSettings get settings => _settings;
  List<TasbehCheckpoint> get checkpoints => List.unmodifiable(_checkpoints);
  bool get isInfinite => _target == null;
  bool get isComplete => _target != null && _count >= _target!;

  double get progress {
    final target = _target;
    if (target == null || target == 0) return 0;
    return math.min(_count / target, 1.0);
  }

  String get progressLabel => _target == null
      ? '∞ mode'
      : isComplete
          ? 'Target complete'
          : '${(progress * 100).round()}% complete';

  Future<void> initialize() async {
    if (_ready) return;
    final state = await _storage.read();
    _count = math.max(0, state.count);
    _target = state.target;
    if (_target != null && _target! <= 0) _target = 100;
    _settings = state.settings;
    _checkpoints = List.unmodifiable(state.checkpoints.take(50));
    _ready = true;
    notifyListeners();
  }

  Future<void> increment() async {
    if (_target != null && _count >= _target!) return;
    _count += 1;
    notifyListeners();
    await _persist();
  }

  Future<void> decrement() async {
    if (_count == 0) return;
    _count -= 1;
    notifyListeners();
    await _persist();
  }

  Future<void> reset() async {
    _count = 0;
    notifyListeners();
    await _persist();
  }

  Future<void> setTarget(int? target) async {
    if (target != null && target <= 0) return;
    _target = target;
    if (target != null && _count > target) _count = target;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _persist();
  }

  Future<void> setPalette(CounterPalette palette) async {
    _settings = _settings.copyWith(palette: palette);
    notifyListeners();
    await _persist();
  }

  Future<void> setTextTone(TextTone tone) async {
    _settings = _settings.copyWith(textTone: tone);
    notifyListeners();
    await _persist();
  }

  Future<void> saveCheckpoint() async {
    final checkpoint = TasbehCheckpoint(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      count: _count,
      target: _target,
    );
    _checkpoints = List.unmodifiable([checkpoint, ..._checkpoints].take(50));
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCheckpoint(String id) async {
    _checkpoints = List.unmodifiable(
      _checkpoints.where((checkpoint) => checkpoint.id != id),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> clearHistory() async {
    _checkpoints = const [];
    notifyListeners();
    await _persist();
  }

  PersistedState get _snapshot => PersistedState(
        count: _count,
        target: _target,
        settings: _settings,
        checkpoints: _checkpoints,
      );

  Future<void> _persist() {
    final snapshot = _snapshot;
    _writeQueue = _writeQueue.then((_) => _storage.write(snapshot));
    return _writeQueue;
  }
}

