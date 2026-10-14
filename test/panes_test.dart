import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/panes/input.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';

/// Taps the switch inside the widget with [key] (rows put the key on the switch itself).
Future<void> toggle(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
}

/// The switch of a [SwitchRow] titled [title].
Finder switchOf(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
  matching: find.byType(SilicaSwitch),
);

void main() {
  testWidgets('Wi-Fi: the switch turns it on through the daemon', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      pane: PaneId.wifi,
      system: FakeSystem(
        const SystemState(reachable: true, wifiAvailable: true),
      ),
    );
    await toggle(tester, 'wifi switch');
    expect(h.system.calls, contains('setWifiEnabled true'));
  });

  testWidgets('Wi-Fi: the current network, saved ones to join, others listed', (
    tester,
  ) async {
    final system =
        FakeSystem(
            const SystemState(
              reachable: true,
              wifiAvailable: true,
              wifiEnabled: true,
              wifiSsid: 'Home',
            ),
          )
          ..networks = const [
            WifiNetwork(
              ssid: 'Home',
              strength: 80,
              secured: true,
              saved: true,
              inUse: true,
            ),
            WifiNetwork(
              ssid: 'Office',
              strength: 60,
              secured: true,
              saved: true,
              inUse: false,
            ),
            WifiNetwork(
              ssid: 'Cafe',
              strength: 30,
              secured: false,
              saved: false,
              inUse: false,
            ),
          ];
    final h = await pumpSettings(tester, pane: PaneId.wifi, system: system);
    await tester.pump();
    expect(find.byKey(const ValueKey('current Home')), findsOneWidget);
    expect(find.byKey(const ValueKey('other Cafe')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('known Office')),
        matching: find.text('Connect'),
      ),
    );
    await tester.pump();
    expect(h.system.calls, contains('connectWifi Office'));
  });

  testWidgets('Wi-Fi without a device: the switch takes no input', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.wifi);
    await toggle(tester, 'wifi switch');
    expect(h.system.calls, isEmpty);
    expect(find.text('No Wi-Fi device found'), findsOneWidget);
  });

  testWidgets('Bluetooth: paired devices connect and disconnect', (
    tester,
  ) async {
    final system =
        FakeSystem(
            const SystemState(
              reachable: true,
              bluetoothAvailable: true,
              bluetoothPowered: true,
            ),
          )
          ..devices = const [
            BluetoothDevice(
              address: 'AA:BB',
              name: 'Headphones',
              icon: 'audio-headphones',
              connected: true,
            ),
          ];
    final h = await pumpSettings(
      tester,
      pane: PaneId.bluetooth,
      system: system,
    );
    await tester.pump();
    await tester.tap(find.text('Disconnect'));
    await tester.pump();
    expect(h.system.calls, contains('connectBluetooth AA:BB false'));
  });

  testWidgets('Appearance: Dark goes through the daemon', (tester) async {
    final h = await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('mode dark')));
    await tester.pump();
    expect(h.system.calls, contains('setDark true'));
    // Automatic has no schedule yet: no call.
    await tester.tap(find.byKey(const ValueKey('mode automatic')));
    await tester.pump();
    expect(h.system.calls, isNot(contains('setDark false')));
  });

  testWidgets('Appearance: the accent is saved and drawn by the window', (
    tester,
  ) async {
    final h = await pumpSettings(tester);
    await tester.tap(find.byKey(const ValueKey('accent green')));
    await tester.pump();
    expect(h.config.read('theme')['accent'], 'green');
    expect(find.text('Green'), findsOneWidget);
    final accent = tester.widget<ControlAccent>(
      find.byType(ControlAccent).first,
    );
    expect(accent.color, const Color(0xFF5FB644));
  });

  testWidgets('Desktop & Dock: the switches write dock.json', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.desktopDock);
    await tester.tap(switchOf('Magnification'));
    await tester.pump();
    await tester.tap(switchOf('Show suggested and recent apps'));
    await tester.pump();
    expect(h.config.read('dock'), {'magnify': false, 'recents': true});
  });

  testWidgets('Desktop & Dock: the hot corners sheet opens and closes', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.desktopDock, height: 1400);
    await tester.tap(find.byKey(const ValueKey('hot corners')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hot corners done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hot corners done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hot corners done')), findsNothing);
  });

  testWidgets('Wallpaper: a colour replaces the choice in wallpaper.json', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.wallpaper);
    await tester.tap(find.byKey(const ValueKey('wallpaper {color: #7a7b80}')));
    await tester.pump();
    expect(h.config.read('wallpaper'), {'color': '#7a7b80'});
    await tester.tap(find.byKey(const ValueKey('wallpaper {}')));
    await tester.pump();
    expect(h.config.read('wallpaper'), <String, Object?>{});
  });

  testWidgets('Keyboard: the repeat sliders write keyboard.json', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.keyboard);
    final rate = find.byKey(const ValueKey('repeat rate'));
    await tester.drag(rate, const Offset(400, 0));
    await tester.pump();
    expect(h.config.read('keyboard')['repeatRate'], repeatRateSteps.last);
    final delay = find.byKey(const ValueKey('repeat delay'));
    await tester.drag(delay, const Offset(-400, 0));
    await tester.pump();
    expect(h.config.read('keyboard')['repeatDelay'], repeatDelaySteps.first);
  });

  testWidgets('Keyboard: the shortcuts sheet lists Silica bindings', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.keyboard);
    await tester.tap(find.byKey(const ValueKey('shortcuts')));
    await tester.pumpAndSettle();
    expect(find.text('Logo ⇧ 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shortcut category 2')));
    await tester.pump();
    expect(find.text('Logo Space'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shortcuts done')));
    await tester.pumpAndSettle();
  });

  testWidgets('Sound: volume and mute go through the daemon', (tester) async {
    final system = FakeSystem(
      const SystemState(reachable: true, audioAvailable: true, volume: 0.5),
    )..outputs = const [AudioOutput(id: 41, name: 'Speakers', isDefault: true)];
    final h = await pumpSettings(tester, pane: PaneId.sound, system: system);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mute')));
    await tester.pump();
    expect(h.system.calls, contains('setMuted true'));
    final slider = find.byKey(const ValueKey('output volume'));
    await tester.tapAt(tester.getCenter(slider) + const Offset(60, 0));
    await tester.pump();
    expect(h.system.calls, contains('setVolume'));
    expect(find.text('Speakers'), findsOneWidget);
  });

  testWidgets('Focus: Do Not Disturb goes through the daemon', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.focus);
    await toggle(tester, 'dnd switch');
    expect(h.system.calls, contains('setDoNotDisturb true'));
  });

  testWidgets('Lock Screen: the choices are saved for the lock screen', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.lockScreen);
    await tester.tap(switchOf('Show password hints'));
    await tester.pump();
    expect(h.config.read('lockscreen')['showHints'], isTrue);
  });

  testWidgets('General › About shows the machine', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.general, height: 1200);
    await tester.tap(find.byKey(const ValueKey('general about')));
    await tester.pump();
    expect(h.navigation.location.sub, SubPaneId.about);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Silica 0.1.0 (alpha)'), findsOneWidget);
    expect(find.text('Test CPU 3000 (2 cores)'), findsOneWidget);
    expect(find.text('16.4 GB'), findsOneWidget);
    expect(find.text('6.99.0-test'), findsOneWidget);
  });

  testWidgets('General › Storage reads the disk', (tester) async {
    final h = await pumpSettings(
      tester,
      pane: PaneId.general,
      run: (executable, arguments) async => executable == 'df'
          ? '      Size     Avail\n500000000000 200000000000\n'
          : null,
    );
    h.navigation.openSub(SubPaneId.storage);
    await tester.pump();
    await tester.pump();
    expect(find.text('200 GB available of 500 GB'), findsOneWidget);
  });

  testWidgets('Printers lists CUPS printers', (tester) async {
    await pumpSettings(
      tester,
      pane: PaneId.printers,
      run: (executable, arguments) async => executable == 'lpstat'
          ? 'printer Laser is idle.\nsystem default destination: Laser\n'
          : null,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('printer Laser')), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
  });

  for (final pane in [
    PaneId.vpn,
    PaneId.energy,
    PaneId.menuBar,
    PaneId.notifications,
    PaneId.screenTime,
    PaneId.privacy,
    PaneId.password,
    PaneId.internetAccounts,
    PaneId.mouse,
    PaneId.accessibility,
    PaneId.search,
  ]) {
    testWidgets('${pane.name}: no backend, shown as not available', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: pane);
      expect(find.byKey(const ValueKey('unavailable')), findsWidgets);
      // Nothing reaches the system from these panes.
      for (final s in find.byType(SilicaSwitch).evaluate()) {
        await tester.tap(find.byWidget(s.widget), warnIfMissed: false);
      }
      await tester.pump();
      expect(h.system.calls, isEmpty);
    });
  }

  testWidgets('every pane builds in light and dark without errors', (
    tester,
  ) async {
    final h = await pumpSettings(tester);
    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      for (final pane in PaneId.values) {
        h.navigation.openPane(pane);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: pane.name);
      }
      for (final sub in SubPaneId.values) {
        h.navigation.openSub(sub);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: sub.name);
        h.navigation.openPane(PaneId.general);
        await tester.pump();
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
