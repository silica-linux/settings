// The displays and the night light as silica-daemon reports them (`System1.Outputs`, the
// `displays` state key, `nightlight.*`; silica-desktop docs/control.md, docs/daemon.md).

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A display mode.
@immutable
class OutputMode {
  const OutputMode({
    required this.width,
    required this.height,
    this.refresh = 0,
    this.preferred = false,
  });

  final int width;
  final int height;

  /// In Hz; 0 when the display does not say.
  final double refresh;
  final bool preferred;

  /// `2560x1440`, the key of a size.
  String get size => '${width}x$height';

  Map<String, Object?> toJson() => {
    'width': width,
    'height': height,
    if (refresh > 0) 'refresh': refresh,
    'preferred': preferred,
  };

  static OutputMode? fromJson(Object? json) {
    if (json is! Map) return null;
    final width = json['width'];
    final height = json['height'];
    if (width is! num || height is! num || width <= 0 || height <= 0) {
      return null;
    }
    final refresh = json['refresh'];
    return OutputMode(
      width: width.toInt(),
      height: height.toInt(),
      refresh: refresh is num && refresh.isFinite ? refresh.toDouble() : 0,
      preferred: json['preferred'] == true,
    );
  }
}

/// A size a display can look like (HiDPI scaled modes, silica-desktop docs/displays.md):
/// `scaled` is false for the native size, which is listed first.
@immutable
class LookSize {
  const LookSize(this.width, this.height, {this.scaled = false});

  final int width;
  final int height;
  final bool scaled;

  /// `1536x960`, the key of a size.
  String get size => '${width}x$height';

  Map<String, Object?> toJson() => {
    'width': width,
    'height': height,
    'scaled': scaled,
  };

  static LookSize? fromJson(Object? json) {
    if (json is! Map) return null;
    final width = json['width'];
    final height = json['height'];
    if (width is! num || height is! num || width <= 0 || height <= 0) {
      return null;
    }
    return LookSize(
      width.toInt(),
      height.toInt(),
      scaled: json['scaled'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LookSize &&
      other.width == width &&
      other.height == height &&
      other.scaled == scaled;

  @override
  int get hashCode => Object.hash(width, height, scaled);
}

/// A display (Ossido's `output.list`).
@immutable
class OutputInfo {
  const OutputInfo({
    required this.connector,
    this.identity = '',
    this.make = '',
    this.model = '',
    this.modes = const [],
    this.current,
    this.scale = 1,
    this.transform = 'normal',
    this.enabled = true,
    this.primary = false,
    this.logical,
    this.hidpi = false,
    this.looksLike = const [],
  });

  final String connector;

  /// The key Ossido saves the display's choices under (`displays.json`).
  final String identity;
  final String make;
  final String model;
  final List<OutputMode> modes;
  final OutputMode? current;
  final double scale;

  /// `normal`, `90`, `180`, `270`, `flipped`, `flipped-90`…
  final String transform;

  /// Driven by the compositor now; only that display can be configured.
  final bool enabled;
  final bool primary;

  /// The size the display looks like in a scaled mode; null at the native size.
  final LookSize? logical;

  /// Whether a scaled (HiDPI) mode is on.
  final bool hidpi;

  /// The sizes it can look like, the native one first; empty when the compositor does not
  /// say (an older Ossido): the choice is then not offered.
  final List<LookSize> looksLike;

  /// Whether the display is in a scaled mode now.
  bool get scaledMode =>
      hidpi ||
      (logical != null && looksLike.isNotEmpty && logical != looksLike.first);

  /// The size it looks like now: the scaled size, or the native one.
  LookSize? get looksNow =>
      scaledMode ? logical : (looksLike.isEmpty ? null : looksLike.first);

  /// The model's name when the display has one, otherwise the connector.
  String get name => model.isNotEmpty ? model : connector;

  Map<String, Object?> toJson() => {
    'connector': connector,
    'identity': identity,
    'make': make,
    'model': model,
    'modes': [for (final m in modes) m.toJson()],
    'current': current?.toJson(),
    'scale': scale,
    'transform': transform,
    'enabled': enabled,
    'primary': primary,
    if (logical != null) 'logical': logical!.toJson(),
    'hidpi': hidpi,
    'looksLike': [for (final l in looksLike) l.toJson()],
  };

  static OutputInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final connector = json['connector'];
    if (connector is! String || connector.isEmpty) return null;
    String text(String key) => json[key] is String ? json[key] as String : '';
    final modes = json['modes'];
    final scale = json['scale'];
    return OutputInfo(
      connector: connector,
      identity: text('identity'),
      make: text('make'),
      model: text('model'),
      modes: modes is List
          ? [
              for (final m in modes)
                if (OutputMode.fromJson(m) case final mode?) mode,
            ]
          : const [],
      current: OutputMode.fromJson(json['current']),
      scale: scale is num && scale.isFinite && scale > 0 ? scale.toDouble() : 1,
      transform: text('transform').isEmpty ? 'normal' : text('transform'),
      enabled: json['enabled'] != false,
      primary: json['primary'] == true,
      logical: LookSize.fromJson(json['logical']),
      hidpi: json['hidpi'] == true,
      looksLike: json['looksLike'] is List
          ? [
              for (final l in json['looksLike'] as List)
                if (LookSize.fromJson(l) case final look?) look,
            ]
          : const [],
    );
  }

  /// The JSON array of `Outputs()` or of the `displays` state key; empty when it is neither.
  static List<OutputInfo> parseList(String json) {
    if (json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      return decoded is List
          ? [
              for (final o in decoded)
                if (fromJson(o) case final info?) info,
            ]
          : const [];
    } on FormatException {
      return const [];
    }
  }

  /// The distinct sizes of [modes], largest first.
  List<OutputMode> get sizes {
    final seen = <String>{};
    final list = [
      for (final m in modes)
        if (seen.add(m.size)) m,
    ]..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    return list;
  }

  /// The refresh rates [modes] offers at [size], highest first.
  List<double> refreshesAt(String size) {
    final rates = <double>{
      for (final m in modes)
        if (m.size == size && m.refresh > 0) m.refresh,
    }.toList()..sort((a, b) => b.compareTo(a));
    return rates;
  }
}

/// The night light's settings and whether it is warming the displays now
/// (`nightlight.*` in the daemon's state).
@immutable
class NightLight {
  const NightLight({
    this.enabled = false,
    this.temperature = defaultTemperature,
    this.schedule = 'off',
    this.from = '21:00',
    this.to = '07:00',
    this.active = false,
  });

  static const int minTemperature = 1900;
  static const int maxTemperature = 6500;
  static const int defaultTemperature = 3400;

  final bool enabled;

  /// In kelvin, 1900 (warm) to 6500 (neutral).
  final int temperature;

  /// `off` (on while enabled), `sunset` (sunset to sunrise) or `custom` (from to to).
  final String schedule;
  final String from;
  final String to;
  final bool active;

  /// `HH:MM`, 00:00 to 23:59.
  static bool validTime(String time) =>
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time);
}
