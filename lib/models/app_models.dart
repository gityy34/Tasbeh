import 'dart:convert';

enum AppThemeMode { auto, day, night }

enum CounterPalette { water, realisticWater, nature, sunrise, midnight }

enum TextTone { white, navy, cream }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.auto => 'Auto',
        AppThemeMode.day => 'Day',
        AppThemeMode.night => 'Night',
      };
}

extension CounterPaletteLabel on CounterPalette {
  String get label => switch (this) {
        CounterPalette.water => 'Water',
        CounterPalette.realisticWater => 'Realistic Water Theme',
        CounterPalette.nature => 'Nature',
        CounterPalette.sunrise => 'Light',
        CounterPalette.midnight => 'Dark',
      };
}

extension TextToneLabel on TextTone {
  String get label => switch (this) {
        TextTone.white => 'White',
        TextTone.navy => 'Navy',
        TextTone.cream => 'Cream',
      };
}

class TasbehSettings {
  const TasbehSettings({
    this.themeMode = AppThemeMode.auto,
    this.palette = CounterPalette.water,
    this.textTone = TextTone.white,
  });

  final AppThemeMode themeMode;
  final CounterPalette palette;
  final TextTone textTone;

  TasbehSettings copyWith({
    AppThemeMode? themeMode,
    CounterPalette? palette,
    TextTone? textTone,
  }) {
    return TasbehSettings(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      textTone: textTone ?? this.textTone,
    );
  }

  Map<String, Object> toJson() => {
        'themeMode': themeMode.name,
        'palette': palette.name,
        'textTone': textTone.name,
      };

  factory TasbehSettings.fromJson(Map<String, dynamic> json) {
    return TasbehSettings(
      themeMode: _enumOrDefault(
        AppThemeMode.values,
        json['themeMode'] as String?,
        AppThemeMode.auto,
      ),
      palette: _enumOrDefault(
        CounterPalette.values,
        json['palette'] as String?,
        CounterPalette.water,
      ),
      textTone: _enumOrDefault(
        TextTone.values,
        json['textTone'] as String?,
        TextTone.white,
      ),
    );
  }
}

T _enumOrDefault<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class TasbehCheckpoint {
  const TasbehCheckpoint({
    required this.id,
    required this.createdAt,
    required this.count,
    required this.target,
  });

  final String id;
  final DateTime createdAt;
  final int count;
  final int? target;

  String get targetLabel => target == null ? '∞' : '$target';

  Map<String, Object?> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'count': count,
        'target': target,
      };

  factory TasbehCheckpoint.fromJson(Map<String, dynamic> json) {
    return TasbehCheckpoint(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      count: (json['count'] as num).toInt(),
      target: (json['target'] as num?)?.toInt(),
    );
  }
}

class PersistedState {
  const PersistedState({
    required this.count,
    required this.target,
    required this.settings,
    required this.checkpoints,
  });

  const PersistedState.defaults()
      : count = 0,
        target = 100,
        settings = const TasbehSettings(),
        checkpoints = const <TasbehCheckpoint>[];

  final int count;
  final int? target;
  final TasbehSettings settings;
  final List<TasbehCheckpoint> checkpoints;

  Map<String, Object?> toJson() => {
        'count': count,
        'target': target,
        'settings': settings.toJson(),
        'checkpoints': checkpoints.map((item) => item.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory PersistedState.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rawCheckpoints = json['checkpoints'] as List<dynamic>? ?? const [];
    return PersistedState(
      count: (json['count'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt(),
      settings: TasbehSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
      checkpoints: rawCheckpoints
          .map((item) => TasbehCheckpoint.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

