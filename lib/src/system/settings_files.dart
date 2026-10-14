// The configuration files Ossido and silica-daemon read and Settings writes: keyboard.json
// (key repeat and input sources), input.json (mouse and touchpad), sound.json (alerts), power.json
// (display off, sleep) and focus.json (Focus modes). The contract is silica-desktop's
// docs/control.md and docs/daemon.md; each helper writes one key (or one device's key) and
// keeps the rest, like [ConfigStore.write].

import 'config.dart';

/// keyboard.json limits.
abstract final class KeyboardLimits {
  static const int delayMin = 100;
  static const int delayMax = 3000;
  static const int rateMax = 100;
  static const int maxLayouts = 4;

  /// Ossido's defaults when neither the file nor the environment says.
  static const int delayDefault = 375;
  static const int rateDefault = 11;
}

/// An input source: an xkb layout, with a variant in parentheses (`de(nodeadkeys)`).
String layoutId(String layout, [String variant = '']) =>
    variant.isEmpty ? layout : '$layout($variant)';

/// `de(nodeadkeys)` → (`de`, `nodeadkeys`).
(String layout, String variant) splitLayout(String id) {
  final open = id.indexOf('(');
  if (open < 0 || !id.endsWith(')')) return (id, '');
  return (id.substring(0, open), id.substring(open + 1, id.length - 1));
}

/// pointer settings of one device in input.json (`mouse` or `touchpad`).
enum PointerDevice { mouse, touchpad }

/// Which button is the mouse's secondary click (input.json `mouse.secondaryClick`).
enum MouseSecondary { right, left }

/// How the touchpad makes a secondary click (input.json `touchpad.secondaryClick`).
enum TouchpadSecondary { twoFinger, bottomRight, bottomLeft }

abstract final class PointerLimits {
  static const double speedMin = -1;
  static const double speedMax = 1;
  static const double scrollMin = 0.1;
  static const double scrollMax = 10;
}

extension SettingsFiles on ConfigStore {
  // keyboard.json ---------------------------------------------------------------------

  /// The delay saved, in ms; null when the file has none (Ossido's default applies).
  int? get savedRepeatDelay {
    final v = read('keyboard')['repeatDelay'];
    return v is num && v.isFinite
        ? v.round().clamp(KeyboardLimits.delayMin, KeyboardLimits.delayMax)
        : null;
  }

  /// The repeat rate saved, per second (0: off); null when the file has none.
  int? get savedRepeatRate {
    final v = read('keyboard')['repeatRate'];
    return v is num && v.isFinite
        ? v.round().clamp(0, KeyboardLimits.rateMax)
        : null;
  }

  bool writeRepeatDelay(int ms) => write(
    'keyboard',
    'repeatDelay',
    ms.clamp(KeyboardLimits.delayMin, KeyboardLimits.delayMax),
  );

  bool writeRepeatRate(int perSecond) => write(
    'keyboard',
    'repeatRate',
    perSecond.clamp(0, KeyboardLimits.rateMax),
  );

  /// The input sources saved, in order; empty when Ossido uses xkb's default.
  List<String> get savedLayouts {
    final v = read('keyboard')['layouts'];
    return v is List
        ? [
            for (final e in v)
              if (e is String && e.isNotEmpty) e,
          ].take(KeyboardLimits.maxLayouts).toList()
        : const [];
  }

  /// Saves the input sources (at most four); an empty list removes the key.
  bool writeLayouts(List<String> layouts) {
    final list = layouts.take(KeyboardLimits.maxLayouts).toList();
    return write('keyboard', 'layouts', list.isEmpty ? null : list);
  }

  // input.json ------------------------------------------------------------------------

  Map<String, Object?> _device(PointerDevice device) {
    final v = read('input')[device.name];
    return v is Map ? {for (final e in v.entries) '${e.key}': e.value} : {};
  }

  /// One key of one device, keeping the device's other keys and the other device.
  bool writePointer(PointerDevice device, String key, Object? value) {
    final input = read('input');
    final entry = _device(device);
    if (value == null) {
      entry.remove(key);
    } else {
      entry[key] = value;
    }
    input[device.name] = entry;
    return replace('input', input);
  }

  double pointerSpeed(PointerDevice device) {
    final v = _device(device)['speed'];
    return v is num && v.isFinite
        ? v.toDouble().clamp(PointerLimits.speedMin, PointerLimits.speedMax)
        : 0;
  }

  double pointerScrollSpeed(PointerDevice device) {
    final v = _device(device)['scrollSpeed'];
    return v is num && v.isFinite
        ? v.toDouble().clamp(PointerLimits.scrollMin, PointerLimits.scrollMax)
        : 1;
  }

  bool pointerFlag(PointerDevice device, String key, {required bool fallback}) {
    final v = _device(device)[key];
    return v is bool ? v : fallback;
  }

  String pointerText(
    PointerDevice device,
    String key, {
    required String fallback,
  }) {
    final v = _device(device)[key];
    return v is String ? v : fallback;
  }

  bool writePointerSpeed(PointerDevice device, double speed) => writePointer(
    device,
    'speed',
    double.parse(
      speed
          .clamp(PointerLimits.speedMin, PointerLimits.speedMax)
          .toStringAsFixed(2),
    ),
  );

  bool writeScrollSpeed(PointerDevice device, double speed) => writePointer(
    device,
    'scrollSpeed',
    double.parse(
      speed
          .clamp(PointerLimits.scrollMin, PointerLimits.scrollMax)
          .toStringAsFixed(2),
    ),
  );

  // sound.json ------------------------------------------------------------------------

  double get alertVolume {
    final v = read('sound')['alertVolume'];
    return v is num && v.isFinite ? v.toDouble().clamp(0, 1) : 1;
  }

  bool writeAlertVolume(double volume) => write(
    'sound',
    'alertVolume',
    double.parse(volume.clamp(0, 1).toStringAsFixed(2)),
  );

  // power.json ------------------------------------------------------------------------

  /// Minutes of idle time before [key] (`displayOffMinutes`, `sleepMinutes`); 0: never.
  double idleMinutes(String key) {
    final v = read('power')[key];
    return v is num && v.isFinite && v > 0 ? v.toDouble() : 0;
  }

  bool writeIdleMinutes(String key, int minutes) =>
      write('power', key, minutes <= 0 ? 0 : minutes);
}
