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
  });

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

  HostInfo read() {
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
    );
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
