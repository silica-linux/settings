// Helpers of the pane tests: tapping, switches, form pop-ups, and fake network data.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_settings/src/ui/popup.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';

/// Taps the widget with [key].
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The switch of the row with [key] (or of the widget itself when it is a switch).
Finder switchIn(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(SilicaSwitch),
  matchRoot: true,
);

/// Opens the form pop-up of the row with [key] and chooses [item].
Future<void> choose(WidgetTester tester, String key, String item) async {
  await tester.tap(
    find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byWidgetPredicate((w) => w is FormPopUp),
          matchRoot: true,
        )
        .first,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(item).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Fills the window and waits for the tools' futures.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const wifiOn = SystemState(
  reachable: true,
  wifiAvailable: true,
  wifiEnabled: true,
  wifiSsid: 'Home',
  wifiStrength: 80,
);

FakeTools networkTools() => FakeTools()
  ..points = const [
    AccessPoint(ssid: 'Home', strength: 80, security: 'WPA2', inUse: true),
    AccessPoint(ssid: 'Office', strength: 60, security: 'WPA2', inUse: false),
    AccessPoint(ssid: 'Cafe', strength: 30, security: 'WPA2', inUse: false),
    AccessPoint(ssid: 'Library', strength: 20, security: '', inUse: false),
  ]
  ..connections = const [
    SavedConnection(name: 'Home', type: '802-11-wireless', active: true),
    SavedConnection(name: 'Office', type: '802-11-wireless', active: false),
    SavedConnection(name: 'Work', type: 'wireguard', active: false),
  ]
  ..devices = const [
    NetworkDevice(
      name: 'wlp2s0',
      type: 'wifi',
      state: 'connected',
      connection: 'Home',
    ),
    NetworkDevice(
      name: 'enp3s0',
      type: 'ethernet',
      state: 'unavailable',
      connection: '',
    ),
    NetworkDevice(
      name: 'lo',
      type: 'loopback',
      state: 'connected',
      connection: 'lo',
    ),
  ]
  ..details = const {
    'wlp2s0': DeviceDetails(
      hardwareAddress: 'AA:BB:CC:DD:EE:FF',
      ipv4: ['192.168.1.20/24'],
      gateway: '192.168.1.1',
      dns: ['192.168.1.1'],
    ),
  };
