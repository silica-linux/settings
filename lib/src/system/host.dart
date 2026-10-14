// What Settings reads about the machine without a service: the OS from os-release, the
// hardware from /proc and /sys, the user from passwd, the disk from df, the time zone and the
// language from the system, the printers from CUPS (lpstat). Every read may fail: the panes
// show what is known.

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Runs a program and returns its standard output, or null.
typedef CommandRunner =
    Future<String?> Function(String executable, List<String> arguments);

Future<String?> runCommand(String executable, List<String> arguments) async {
  try {
    final result = await Process.run(executable, arguments);
    return result.exitCode == 0 ? '${result.stdout}' : null;
  } on ProcessException {
    return null;
  }
}

/// The disk holding the system: total and available bytes.
@immutable
class DiskUsage {
  const DiskUsage({required this.total, required this.available});
  final int total;
  final int available;
  int get used => total - available;
}

@immutable
class Printer {
  const Printer({required this.name, required this.isDefault});
  final String name;
  final bool isDefault;
}

@immutable
class HostInfo {
  const HostInfo({
    this.osName = '',
    this.osVersion = '',
    this.osPrettyName = '',
    this.hostname = '',
    this.vendor = '',
    this.model = '',
    this.cpu = '',
    this.cpuCount = 0,
    this.memoryBytes = 0,
    this.kernel = '',
    this.userLogin = '',
    this.userName = '',
    this.timezone = '',
    this.language = '',
    this.graphics = const [],
    this.firmware = '',
  });

  /// The graphics adapters (`/sys/class/drm/card*/device`, named from pci.ids).
  final List<String> graphics;

  /// The firmware's version (`/sys/class/dmi/id/bios_version`).
  final String firmware;

  final String osName;
  final String osVersion;
  final String osPrettyName;
  final String hostname;
  final String vendor;
  final String model;
  final String cpu;
  final int cpuCount;
  final int memoryBytes;
  final String kernel;
  final String userLogin;

  /// The full name from passwd (GECOS), the login when it is empty.
  final String userName;
  final String timezone;
  final String language;

  /// The same information with the graphics adapters filled in (read when About opens).
  HostInfo withGraphics(List<String> graphics) => HostInfo(
    osName: osName,
    osVersion: osVersion,
    osPrettyName: osPrettyName,
    hostname: hostname,
    vendor: vendor,
    model: model,
    cpu: cpu,
    cpuCount: cpuCount,
    memoryBytes: memoryBytes,
    kernel: kernel,
    userLogin: userLogin,
    userName: userName,
    timezone: timezone,
    language: language,
    graphics: graphics,
    firmware: firmware,
  );
}

/// Reads [HostInfo] from a root folder (`/` normally, a fixture in tests).
class HostReader {
  HostReader({this.root = '', Map<String, String>? env, this.run = runCommand})
    : env = env ?? Platform.environment;

  final String root;
  final Map<String, String> env;
  final CommandRunner run;

  String? _read(String path) {
    try {
      final file = File('$root$path');
      return file.existsSync() ? file.readAsStringSync() : null;
    } on FileSystemException {
      return null;
    }
  }

  /// `KEY=value` lines (os-release), quotes removed.
  static Map<String, String> parseKeyValues(String text) => {
    for (final line in text.split('\n'))
      if (line.contains('=') && !line.trimLeft().startsWith('#'))
        line.substring(0, line.indexOf('=')).trim(): _unquote(
          line.substring(line.indexOf('=') + 1).trim(),
        ),
  };

  static String _unquote(String value) =>
      value.length >= 2 &&
          (value.startsWith('"') && value.endsWith('"') ||
              value.startsWith("'") && value.endsWith("'"))
      ? value.substring(1, value.length - 1)
      : value;

  /// The information of the machine. The graphics adapters take the most (pci.ids is more
  /// than a megabyte), so the window starts without them ([HostInfo.withGraphics],
  /// [graphics]).
  HostInfo read({bool withGraphics = true}) {
    final os = parseKeyValues(
      _read('/etc/os-release') ?? _read('/usr/lib/os-release') ?? '',
    );
    final cpuinfo = _read('/proc/cpuinfo') ?? '';
    final models = RegExp(
      r'^model name\s*:\s*(.+)$',
      multiLine: true,
    ).allMatches(cpuinfo).map((m) => m.group(1)?.trim() ?? '').toList();
    final memory = RegExp(
      r'^MemTotal:\s*(\d+)\s*kB',
      multiLine: true,
    ).firstMatch(_read('/proc/meminfo') ?? '');
    final login = env['USER'] ?? env['LOGNAME'] ?? '';
    var name = '';
    for (final line in (_read('/etc/passwd') ?? '').split('\n')) {
      final fields = line.split(':');
      if (fields.length > 4 && fields[0] == login) {
        name = fields[4].split(',').first.trim();
        break;
      }
    }
    return HostInfo(
      osName: os['NAME'] ?? '',
      osVersion: os['VERSION'] ?? os['VERSION_ID'] ?? '',
      osPrettyName: os['PRETTY_NAME'] ?? os['NAME'] ?? '',
      hostname:
          (_read('/etc/hostname') ?? _read('/proc/sys/kernel/hostname') ?? '')
              .trim(),
      vendor: (_read('/sys/class/dmi/id/sys_vendor') ?? '').trim(),
      model: (_read('/sys/class/dmi/id/product_name') ?? '').trim(),
      cpu: models.isEmpty ? '' : models.first,
      cpuCount: models.length,
      memoryBytes: (int.tryParse(memory?.group(1) ?? '') ?? 0) * 1024,
      kernel: (_read('/proc/sys/kernel/osrelease') ?? '').trim(),
      userLogin: login,
      userName: name.isEmpty ? login : name,
      timezone: _timezone(),
      language: env['LANG'] ?? '',
      graphics: withGraphics ? graphics() : const [],
      firmware: (_read('/sys/class/dmi/id/bios_version') ?? '').trim(),
    );
  }

  /// The PCI ids of every DRM card, named through pci.ids when it is installed.
  List<String> graphics() {
    final names = <String>[];
    try {
      final drm = Directory('$root/sys/class/drm');
      if (!drm.existsSync()) return names;
      final cards = [
        for (final e in drm.listSync())
          if (RegExp(r'/card\d+$').hasMatch(e.path)) e.path,
      ]..sort();
      final ids =
          _read('/usr/share/hwdata/pci.ids') ??
          _read('/usr/share/misc/pci.ids') ??
          '';
      for (final card in cards) {
        final relative = card.substring(root.length);
        final vendor = (_read('$relative/device/vendor') ?? '').trim();
        final device = (_read('$relative/device/device') ?? '').trim();
        if (vendor.isEmpty) continue;
        final name = pciName(ids, vendor, device);
        if (!names.contains(name)) names.add(name);
      }
    } on FileSystemException {
      return names;
    }
    return names;
  }

  /// "Vendor Device" from pci.ids for `0x8086` / `0x46a6`; the ids when unknown.
  static String pciName(String ids, String vendor, String device) {
    String hex(String v) =>
        v.toLowerCase().replaceFirst('0x', '').padLeft(4, '0');
    final v = hex(vendor), d = hex(device);
    String? vendorName, deviceName;
    // Straight to the vendor's line: no need to split the whole file.
    final start = ids.startsWith('$v ') ? 0 : ids.indexOf('\n$v ') + 1;
    if (start > 0 || ids.startsWith('$v ')) {
      var at = start;
      var first = true;
      while (at < ids.length) {
        var end = ids.indexOf('\n', at);
        if (end < 0) end = ids.length;
        final line = ids.substring(at, end);
        at = end + 1;
        if (line.isEmpty || line.startsWith('#')) continue;
        if (first) {
          vendorName = line.substring(4).trim();
          first = false;
          continue;
        }
        if (!line.startsWith('\t')) break;
        if (!line.startsWith('\t\t') && line.startsWith('\t$d ')) {
          deviceName = line.substring(6).trim();
          break;
        }
      }
    }
    if (vendorName == null) return '$v:$d';
    final short = vendorName
        .replaceAll(RegExp(r'\s*\[.*?\]'), '')
        .replaceAll(RegExp(r',? (Corporation|Inc\.|Co\., Ltd\.|Ltd\.)$'), '')
        .trim();
    return deviceName == null ? '$short $d' : '$short $deviceName';
  }

  String _timezone() {
    final configured = (_read('/etc/timezone') ?? '').trim();
    if (configured.isNotEmpty) return configured;
    try {
      final link = Link('$root/etc/localtime');
      if (!link.existsSync()) return env['TZ'] ?? '';
      final target = link.targetSync();
      final index = target.indexOf('zoneinfo/');
      return index < 0 ? target : target.substring(index + 'zoneinfo/'.length);
    } on FileSystemException {
      return env['TZ'] ?? '';
    }
  }

  /// The disk of `/` (df in bytes).
  Future<DiskUsage?> disk() async {
    final out = await run('df', ['-B1', '--output=size,avail', '/']);
    if (out == null) return null;
    final lines = out.trim().split('\n');
    if (lines.length < 2) return null;
    final fields = lines[1].trim().split(RegExp(r'\s+'));
    if (fields.length < 2) return null;
    final total = int.tryParse(fields[0]);
    final available = int.tryParse(fields[1]);
    return total == null || available == null
        ? null
        : DiskUsage(total: total, available: available);
  }

  /// The CUPS printers (`lpstat -p -d`); empty without CUPS.
  Future<List<Printer>> printers() async {
    final out = await run('lpstat', ['-p', '-d']);
    if (out == null) return const [];
    final defaultName = RegExp(
      r'^system default destination:\s*(\S+)',
      multiLine: true,
    ).firstMatch(out)?.group(1);
    return [
      for (final m in RegExp(
        r'^printer\s+(\S+)',
        multiLine: true,
      ).allMatches(out))
        Printer(name: m.group(1) ?? '', isDefault: m.group(1) == defaultName),
    ];
  }
}

/// The space a folder takes (`du -sb`), null when it cannot be measured.
Future<int?> folderSize(CommandRunner run, String path) async {
  final out = await run('du', ['-sb', path]);
  if (out == null) return null;
  return int.tryParse(out.trim().split(RegExp(r'\s+')).first);
}

/// The user's trash (freedesktop trash specification): `$XDG_DATA_HOME/Trash`.
String trashFolder(Map<String, String> env) {
  final home = env['HOME'] ?? '';
  final data = env['XDG_DATA_HOME'];
  return '${data != null && data.isNotEmpty ? data : '$home/.local/share'}/Trash';
}

/// Deletes everything in the trash (its files and their info records). False if something
/// could not be removed.
Future<bool> emptyTrash(Map<String, String> env) async {
  var ok = true;
  for (final sub in ['files', 'info', 'expunged']) {
    final dir = Directory('${trashFolder(env)}/$sub');
    try {
      if (!dir.existsSync()) continue;
      for (final entry in dir.listSync(followLinks: false)) {
        try {
          await entry.delete(recursive: true);
        } on FileSystemException {
          ok = false;
        }
      }
    } on FileSystemException {
      ok = false;
    }
  }
  final sizes = File('${trashFolder(env)}/directorysizes');
  try {
    if (sizes.existsSync()) sizes.deleteSync();
  } on FileSystemException {
    ok = false;
  }
  return ok;
}
