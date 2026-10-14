// Silica's configuration files in `$XDG_CONFIG_HOME/silica` (usually ~/.config/silica), the
// same ones the shell and Ossido read: `dock.json` (shell Dock: `magnify`, `recents`,
// `pinned`), `wallpaper.json` (shell wallpaper: `color` or `image`), and the ones Settings
// introduces for the components that will read them: `keyboard.json` (`repeatRate` in keys per
// second, `repeatDelay` in ms, for Ossido's wl_keyboard repeat_info), `theme.json` (accent,
// highlight, sidebar icon size, scroll bars) and `lockscreen.json`. One key changes at a time
// and the others are kept, so Settings never drops what another component wrote.

import 'dart:convert';
import 'dart:io';

/// A folder of small JSON objects.
class ConfigStore {
  ConfigStore(this.directory);

  /// `$XDG_CONFIG_HOME/silica`, or `~/.config/silica`.
  factory ConfigStore.forUser(Map<String, String> env) {
    final home = env['HOME'] ?? '';
    final config = env['XDG_CONFIG_HOME'];
    final base = config != null && config.isNotEmpty ? config : '$home/.config';
    return ConfigStore('$base/silica');
  }

  final String directory;

  File _file(String name) => File('$directory/$name.json');

  /// The object in `name.json`; empty when missing or broken (the defaults then apply).
  Map<String, Object?> read(String name) {
    try {
      final file = _file(name);
      if (!file.existsSync()) return {};
      final json = jsonDecode(file.readAsStringSync());
      return json is Map
          ? {for (final e in json.entries) '${e.key}': e.value}
          : {};
    } on FileSystemException {
      return {};
    } on FormatException {
      return {};
    }
  }

  /// Sets `key` (null removes it) keeping the other keys. False if the file cannot be
  /// written (a read-only home): the choice then lasts only in this window.
  bool write(String name, String key, Object? value) {
    final config = read(name);
    if (value == null) {
      config.remove(key);
    } else {
      config[key] = value;
    }
    return replace(name, config);
  }

  /// Writes the whole object (the wallpaper choice is one of two exclusive keys).
  bool replace(String name, Map<String, Object?> config) {
    try {
      final file = _file(name);
      file.parent.createSync(recursive: true);
      // Write and rename: a reader never sees half a file.
      final temporary = File('${file.path}.tmp');
      temporary.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(config),
      );
      temporary.renameSync(file.path);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  bool flag(String name, String key, {required bool fallback}) {
    final value = read(name)[key];
    return value is bool ? value : fallback;
  }

  double number(String name, String key, {required double fallback}) {
    final value = read(name)[key];
    return value is num && value.isFinite ? value.toDouble() : fallback;
  }

  String text(String name, String key, {required String fallback}) {
    final value = read(name)[key];
    return value is String ? value : fallback;
  }
}
