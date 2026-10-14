// Battery and Energy against fake UPower and power profiles.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Battery and Energy', () {
    final profiles = FakeTools()
      ..powerState = const PowerState(
        profiles: [
          PowerProfile.powerSaver,
          PowerProfile.balanced,
          PowerProfile.performance,
        ],
        active: PowerProfile.balanced,
        secondsToEmpty: 12000,
        capacity: 91,
      );

    testWidgets('Battery: level, time left, health, low power mode', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        tools: profiles,
        system: FakeSystem(
          const SystemState(
            reachable: true,
            batteryPresent: true,
            batteryPercent: 64,
          ),
        ),
      );
      h.navigation.openPane(PaneId.battery);
      await settle(tester);
      expect(find.text('64 %'), findsOneWidget);
      expect(find.text('On battery · 3 h 20 min left'), findsOneWidget);
      expect(find.text('91 %'), findsOneWidget);
      await tester.tap(switchIn('low power mode'));
      await settle(tester);
      expect(h.tools.calls, contains('profile powerSaver'));
    });

    testWidgets('Energy: the power mode', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.energy,
        tools: profiles,
      );
      await settle(tester);
      await choose(tester, 'power mode', 'High performance');
      await settle(tester);
      expect(h.tools.calls, contains('profile performance'));
    });

    testWidgets('Energy without power profiles says why (#68)', (tester) async {
      await pumpSettings(tester, pane: PaneId.energy);
      await settle(tester);
      expect(find.byKey(const ValueKey('power mode')), findsNothing);
      expect(find.textContaining('#68'), findsWidgets);
    });
  });
}
