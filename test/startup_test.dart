// The start: nothing blocks before the first frame, the machine information follows it,
// and the window opens on the pane it was last on.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/app.dart';
import 'package:silica_settings/src/model/navigation.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/services.dart';
import 'package:silica_settings/src/session.dart';
import 'package:silica_settings/src/startup.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/host.dart';

import 'fakes.dart';

void main() {
  testWidgets('the real machine is read after the first frame, not before', (
    tester,
  ) async {
    final env = Platform.environment;
    final home = Directory.systemTemp.createTempSync('startup-home');
    startupBegin();
    final watch = Stopwatch()..start();
    final services = Services(
      system: FakeSystem(),
      config: ConfigStore('${home.path}/config'),
      host: HostReader(env: env, run: (e, a) async => null),
      env: env,
      tools: FakeTools(),
    );
    final constructed = watch.elapsedMicroseconds;
    // A budget far above the few milliseconds it takes: before, the whole machine
    // (cpuinfo, pci.ids) was read here, 65-290 ms on a fast disk.
    expect(constructed, lessThan(50000));
    expect(services.hostInfo.value.osName, isEmpty);

    await tester.pumpWidget(
      SettingsApp(
        locale: const Locale('en'),
        navigation: Navigation(),
        services: services,
      ),
    );
    await tester.pump();
    final marks = startupMarks.map((m) => m.$2).toList();
    expect(
      marks,
      containsAllInOrder([
        'app state created',
        'first frame',
        'host info read',
      ]),
    );
    expect(services.hostInfo.value.cpuCount, greaterThan(0));
    // The adapters are named only when About asks.
    expect(services.hostInfo.value.graphics, isEmpty);
    // ignore: avoid_print
    print(
      'startup: services ${constructed}us; '
      '${[for (final m in startupMarks) '${m.$2} +${m.$1}ms'].join(', ')}',
    );
  });

  test('the window opens on the pane it was last on', () {
    final home = Directory.systemTemp.createTempSync('session-home');
    final config = ConfigStore('${home.path}/config');
    expect(initialPane(const [], config), PaneId.appearance);

    final navigation = Navigation(initial: Location(PaneId.appearance));
    rememberPane(navigation, config);
    navigation.openPane(PaneId.wifi);
    expect(config.text(sessionFile, lastPaneKey, fallback: ''), 'wifi');
    expect(initialPane(const [], config), PaneId.wifi);
    // The command line wins; a broken value falls back to Appearance.
    expect(initialPane(const ['sound'], config), PaneId.sound);
    config.write(sessionFile, lastPaneKey, 'nonsense');
    expect(initialPane(const [], config), PaneId.appearance);
  });
}
