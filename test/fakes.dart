// A fake silica-daemon and a window set up like the real one (832 × 727), for the widget tests.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/app.dart';
import 'package:silica_settings/src/model/navigation.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/services.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/host.dart';
import 'package:silica_settings/src/system/system.dart';

class FakeSystem implements SystemBackend {
  FakeSystem([this.current = const SystemState(reachable: true)]);

  SystemState current;
  final StreamController<SystemState> _states =
      StreamController<SystemState>.broadcast();
  final List<String> calls = [];
  List<WifiNetwork> networks = const [];
  List<BluetoothDevice> devices = const [];
  List<AudioOutput> outputs = const [];

  void emit(SystemState state) {
    current = state;
    _states.add(state);
  }

  @override
  Stream<SystemState> get states async* {
    yield current;
    yield* _states.stream;
  }

  @override
  Future<SystemState> state() async => current;

  @override
  Future<void> setDark(bool dark) async => calls.add('setDark $dark');

  @override
  Future<void> setWifiEnabled(bool enabled) async =>
      calls.add('setWifiEnabled $enabled');

  @override
  Future<List<WifiNetwork>> wifiNetworks() async => networks;

  @override
  Future<void> connectWifi(String ssid) async => calls.add('connectWifi $ssid');

  @override
  Future<void> setBluetoothPowered(bool powered) async =>
      calls.add('setBluetoothPowered $powered');

  @override
  Future<List<BluetoothDevice>> bluetoothDevices() async => devices;

  @override
  Future<void> connectBluetooth(
    String address, {
    required bool connect,
  }) async => calls.add('connectBluetooth $address $connect');

  @override
  Future<void> setVolume(double volume) async => calls.add('setVolume');

  @override
  Future<void> setMuted(bool muted) async => calls.add('setMuted $muted');

  @override
  Future<List<AudioOutput>> audioOutputs() async => outputs;

  @override
  Future<void> setAudioOutput(int id) async => calls.add('setAudioOutput $id');

  @override
  Future<void> setDoNotDisturb(bool enabled) async =>
      calls.add('setDoNotDisturb $enabled');
}

/// A machine folder with os-release, cpuinfo, meminfo, hostname and passwd.
Directory fakeRoot() {
  final root = Directory.systemTemp.createTempSync('settings-root');
  void file(String path, String text) {
    final f = File('${root.path}$path');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(text);
  }

  file(
    '/etc/os-release',
    'NAME="Silica"\nVERSION="0.1.0 (alpha)"\nPRETTY_NAME="Silica 0.1.0 (alpha)"\nID=silica\n',
  );
  file('/etc/hostname', 'silica\n');
  file(
    '/etc/passwd',
    'root:x:0:0:root:/root:/bin/bash\nada:x:1000:1000:Ada Lovelace,,,:/home/ada:/bin/bash\n',
  );
  file(
    '/proc/cpuinfo',
    'processor\t: 0\nmodel name\t: Test CPU 3000\n\nprocessor\t: 1\nmodel name\t: Test CPU 3000\n',
  );
  file('/proc/meminfo', 'MemTotal:       16000000 kB\n');
  file('/proc/sys/kernel/osrelease', '6.99.0-test\n');
  return root;
}

class Harness {
  Harness({
    required this.system,
    required this.config,
    required this.navigation,
  });
  final FakeSystem system;
  final ConfigStore config;
  final Navigation navigation;
}

Future<Harness> pumpSettings(
  WidgetTester tester, {
  FakeSystem? system,
  PaneId pane = PaneId.appearance,
  Locale locale = const Locale('en'),
  Directory? root,
  CommandRunner? run,
  double height = 727,
}) async {
  tester.view.physicalSize = Size(832, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final machine = root ?? fakeRoot();
  final home = Directory.systemTemp.createTempSync('settings-home');
  final env = {
    'HOME': home.path,
    'USER': 'ada',
    'XDG_DATA_DIRS': '${home.path}/none',
    'LANG': 'en_GB.UTF-8',
  };
  final fake = system ?? FakeSystem();
  final config = ConfigStore('${home.path}/.config/silica');
  final navigation = Navigation(initial: Location(pane));
  await tester.pumpWidget(
    SettingsApp(
      locale: locale,
      navigation: navigation,
      services: Services(
        system: fake,
        config: config,
        host: HostReader(
          root: machine.path,
          env: env,
          run: run ?? (executable, arguments) async => null,
        ),
        env: env,
      ),
    ),
  );
  await tester.pump();
  return Harness(system: fake, config: config, navigation: navigation);
}
