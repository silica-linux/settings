// Wi-Fi, Bluetooth, Network and VPN against fake NetworkManager, BlueZ and daemon.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Wi-Fi', () {
    testWidgets('the switch turns it on through the daemon', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.wifi,
        system: FakeSystem(
          const SystemState(reachable: true, wifiAvailable: true),
        ),
      );
      await tester.tap(switchIn('wifi switch'));
      await tester.pump();
      expect(h.system.calls, contains('setWifiEnabled true'));
    });

    testWidgets('the current network, known and other networks', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.wifi,
        system: FakeSystem(wifiOn),
        tools: networkTools(),
      );
      await settle(tester);
      expect(h.tools.calls, contains('rescan'));
      expect(find.byKey(const ValueKey('current Home')), findsOneWidget);
      expect(find.byKey(const ValueKey('known Office')), findsOneWidget);
      expect(find.byKey(const ValueKey('other Cafe')), findsOneWidget);
      // A known network joins with its saved password.
      await tapKey(tester, 'known Office');
      expect(h.tools.calls, contains('joinWifi Office -'));
      // An open network joins at once.
      await tester.tap(find.byKey(const ValueKey('other Library')));
      await settle(tester);
      expect(h.tools.calls, contains('joinWifi Library -'));
    });

    testWidgets('a secured network asks for its password', (tester) async {
      final tools = networkTools();
      final h = await pumpSettings(
        tester,
        pane: PaneId.wifi,
        system: FakeSystem(wifiOn),
        tools: tools,
      );
      await settle(tester);
      await tapKey(tester, 'other Cafe');
      expect(find.text('Join “Cafe”'), findsOneWidget);
      // A refused password keeps the sheet open and says so.
      tools.fail['joinWifi'] = const ToolError(ToolErrorKind.refused);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('join password')),
          matching: find.byType(EditableText),
        ),
        'wrong',
      );
      await tapKey(tester, 'join');
      await settle(tester);
      expect(h.tools.calls, contains('joinWifi Cafe wrong'));
      expect(find.byKey(const ValueKey('join error')), findsOneWidget);
      tools.fail.clear();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('join password')),
          matching: find.byType(EditableText),
        ),
        'secret',
      );
      await tapKey(tester, 'join');
      await settle(tester);
      expect(h.tools.calls, contains('joinWifi Cafe secret'));
    });

    testWidgets('details show the addresses; forgetting the network', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.wifi,
        system: FakeSystem(wifiOn),
        tools: networkTools(),
      );
      await settle(tester);
      await tapKey(tester, 'wifi details');
      await settle(tester);
      expect(find.text('192.168.1.20/24'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      await tester.tap(switchIn('auto join'));
      await settle(tester);
      expect(h.tools.calls, contains('autoconnect Home false'));
      await tapKey(tester, 'forget network');
      await settle(tester);
      expect(h.tools.calls, contains('forget Home'));
    });

    testWidgets('without a device the switch takes no input', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.wifi);
      expect(find.text('No Wi-Fi device found'), findsOneWidget);
      await tester.tap(switchIn('wifi switch'));
      await tester.pump();
      expect(h.system.calls, isEmpty);
    });
  });

  testWidgets('Bluetooth: paired devices connect, nearby ones pair', (
    tester,
  ) async {
    final tools = FakeTools()
      ..peers = const [
        BluetoothPeer(
          path: '/org/bluez/hci0/dev_1',
          address: '11:22',
          name: 'Headphones',
          icon: 'audio-headphones',
          paired: true,
          connected: true,
          battery: 80,
        ),
        BluetoothPeer(
          path: '/org/bluez/hci0/dev_2',
          address: '33:44',
          name: 'Mouse',
          icon: 'input-mouse',
          paired: false,
          connected: false,
        ),
      ];
    final h = await pumpSettings(
      tester,
      pane: PaneId.bluetooth,
      tools: tools,
      system: FakeSystem(
        const SystemState(
          reachable: true,
          bluetoothAvailable: true,
          bluetoothPowered: true,
        ),
      ),
    );
    await settle(tester);
    expect(h.tools.calls, contains('discovery true'));
    expect(find.text('Connected · 80 %'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('device 11:22')),
        matching: find.text('Disconnect'),
      ),
    );
    await settle(tester);
    expect(h.tools.calls, contains('btConnect /org/bluez/hci0/dev_1 false'));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('nearby 33:44')),
        matching: find.text('Connect'),
      ),
    );
    await settle(tester);
    expect(h.tools.calls, contains('pair /org/bluez/hci0/dev_2'));
    await tester.tap(switchIn('bluetooth switch'));
    await tester.pump();
    expect(h.system.calls, contains('setBluetoothPowered false'));
  });

  testWidgets('Network: the services with their state and addresses', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      pane: PaneId.network,
      tools: networkTools(),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('service wlp2s0')), findsOneWidget);
    expect(find.byKey(const ValueKey('service enp3s0')), findsOneWidget);
    expect(find.byKey(const ValueKey('service lo')), findsNothing);
    expect(find.text('Cable unplugged'), findsOneWidget);
    await tapKey(tester, 'service wlp2s0');
    await settle(tester);
    expect(find.text('192.168.1.1'), findsWidgets);
    await tapKey(tester, 'service disconnect');
    await settle(tester);
    expect(h.tools.calls, contains('disconnect wlp2s0'));
  });

  testWidgets('VPN: the configurations connect with their switch', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      pane: PaneId.vpn,
      tools: networkTools(),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('vpn Work')), findsOneWidget);
    await tester.tap(switchIn('vpn Work'));
    await settle(tester);
    expect(h.tools.calls, contains('connection Work true'));
  });
}
