import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/l10n/gen/app_localizations_en.dart';
import 'package:silica_settings/src/accent.dart';
import 'package:silica_settings/src/model/navigation.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/model/titles.dart';
import 'package:silica_settings/src/panes/desktop.dart';
import 'package:silica_settings/src/panes/general.dart';
import 'package:silica_settings/src/panes/input.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/host.dart';
import 'package:silica_settings/src/system/system.dart';

import 'fakes.dart';

void main() {
  test('the daemon state is read from its flat keys', () {
    final state = SystemState.fromDict({
      'wifi.available': true,
      'wifi.enabled': true,
      'wifi.ssid': 'Home',
      'wifi.strength': 140,
      'audio.volume': 0.4,
      'appearance.dark': true,
      'battery.percent': 'broken',
    });
    expect(state.reachable, isTrue);
    expect(state.wifiSsid, 'Home');
    expect(state.wifiStrength, 100);
    expect(state.volume, 0.4);
    expect(state.dark, isTrue);
    expect(state.batteryPercent, 0);
  });

  group('ConfigStore', () {
    late ConfigStore store;
    setUp(() {
      store = ConfigStore(
        '${Directory.systemTemp.createTempSync('cfg').path}/silica',
      );
    });

    test('one key changes, the others stay', () {
      store.replace('dock', {
        'pinned': ['dev.frascella.Mustache'],
      });
      expect(store.write('dock', 'magnify', false), isTrue);
      expect(store.read('dock'), {
        'pinned': ['dev.frascella.Mustache'],
        'magnify': false,
      });
      store.write('dock', 'magnify', null);
      expect(store.read('dock').containsKey('magnify'), isFalse);
    });

    test('a broken or missing file reads as empty', () {
      expect(store.read('nothing'), isEmpty);
      File('${store.directory}/broken.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{not json');
      expect(store.read('broken'), isEmpty);
      expect(store.flag('broken', 'x', fallback: true), isTrue);
    });
  });

  test('the host is read from os-release, /proc and passwd', () {
    final info = HostReader(
      root: fakeRoot().path,
      env: const {'USER': 'ada', 'LANG': 'it_IT.UTF-8'},
    ).read();
    expect(info.osPrettyName, 'Silica 0.1.0 (alpha)');
    expect(info.osVersion, '0.1.0 (alpha)');
    expect(info.hostname, 'silica');
    expect(info.cpu, 'Test CPU 3000');
    expect(info.cpuCount, 2);
    expect(info.memoryBytes, 16000000 * 1024);
    expect(info.userName, 'Ada Lovelace');
    expect(info.language, 'it_IT.UTF-8');
  });

  test('a missing machine gives empty values, no exception', () {
    final info = HostReader(root: '/nonexistent-root', env: const {}).read();
    expect(info.osName, '');
    expect(info.memoryBytes, 0);
  });

  test('df and lpstat output', () async {
    final reader = HostReader(
      root: '/nonexistent-root',
      env: const {},
      run: (exe, args) async => switch (exe) {
        'df' => '     Size    Avail\n1000 250\n',
        'lpstat' =>
          'printer A is idle.\nprinter B disabled\nsystem default destination: B\n',
        _ => null,
      },
    );
    final disk = await reader.disk();
    expect(disk?.used, 750);
    final printers = await reader.printers();
    expect(printers.map((p) => p.name), ['A', 'B']);
    expect(printers.last.isDefault, isTrue);
  });

  test('search finds settings by name, names that start with it first', () {
    final l = AppLocalizationsEn();
    final index = searchIndex(
      l,
      paneGroups(hasBattery: false).expand((g) => g),
    );
    final results = searchMatches(index, 'key');
    expect(results.first.title, 'Keyboard');
    expect(
      results.map((r) => r.title),
      containsAll(['Key repeat rate', 'Keyboard shortcuts']),
    );
    expect(searchMatches(index, '   '), isEmpty);
    // Battery is not in the sidebar without a battery: not searchable either.
    expect(searchMatches(index, 'battery'), isEmpty);
    final about = searchMatches(index, 'processor').single;
    expect(about.path(l), 'General → About');
  });

  test('navigation keeps a history; the same place adds nothing', () {
    final n = Navigation(initial: const Location(PaneId.wifi));
    n.openPane(PaneId.wifi);
    expect(n.canGoBack, isFalse);
    n.openPane(PaneId.sound);
    n.openPane(PaneId.general);
    n.openSub(SubPaneId.about);
    expect(n.location, const Location(PaneId.general, SubPaneId.about));
    n.back();
    n.back();
    expect(n.pane, PaneId.sound);
    n.openPane(PaneId.keyboard);
    expect(n.canGoForward, isFalse);
  });

  test('repeat steps', () {
    expect(repeatRateSteps[nearestStep(repeatRateSteps, 26)], 25);
    expect(repeatDelaySteps[nearestStep(repeatDelaySteps, 610)], 600);
    expect(repeatRateSteps.first, 0);
  });

  test('a notifying app travels in the location', () {
    final detail = encodeAppDetail('org.gnome.Nautilus', 'Files');
    expect(appDetail(detail), ('org.gnome.Nautilus', 'Files'));
    expect(appDetail('plain'), ('plain', 'plain'));
  });

  test('bytes in decimal units', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(16384000000), '16.4 GB');
    expect(formatBytes(500000000000), '500 GB');
  });

  test('wallpaper.json in both directions', () {
    expect(readWallpaper(const {}), isA<DefaultWallpaper>());
    final color = readWallpaper(const {'color': '#7a7b80'});
    expect((color as ColorWallpaper).hex, '#7a7b80');
    expect(color.json, {'color': '#7a7b80'});
    expect(readWallpaper(const {'color': '#zz'}), isA<DefaultWallpaper>());
    expect(readWallpaper(const {'image': '/x.png'}).json, {'image': '/x.png'});
  });

  test('accents: measured fills, unknown names fall back to multicolour', () {
    expect(Accent.parse('red').fill(dark: true), const Color(0xFFFF565B));
    expect(Accent.parse('nope'), Accent.multicolour);
    expect(Accent.multicolour.fill(dark: false), Accent.blue.fill(dark: false));
    expect(Accent.values, hasLength(9));
  });
}
