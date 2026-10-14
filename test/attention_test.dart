// Sound, Notifications and Focus against the fake daemon and PipeWire.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/system/tools.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Sound', () {
    FakeTools audioTools() => FakeTools()
      ..audio = const AudioDevices(
        outputs: [
          AudioDevice(id: 50, name: 'Speakers', isDefault: true, volume: 0.5),
          AudioDevice(
            id: 51,
            name: 'HDMI / DisplayPort Output',
            isDefault: false,
            volume: 1,
          ),
        ],
        inputs: [
          AudioDevice(
            id: 52,
            name: 'USB Microphone',
            isDefault: true,
            volume: 0.7,
          ),
        ],
      );

    testWidgets('outputs, volume and mute', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.sound,
        tools: audioTools(),
        system: FakeSystem(
          const SystemState(
            reachable: true,
            audioAvailable: true,
            volume: 0.5,
            audioName: 'Speakers',
          ),
        ),
      );
      await settle(tester);
      expect(find.text('Speakers'), findsOneWidget);
      expect(find.text('Built-in'), findsOneWidget);
      expect(find.text('HDMI'), findsOneWidget);
      await tapKey(tester, 'audio 51');
      await settle(tester);
      expect(h.tools.calls, contains('defaultAudio 51'));
      await tester.drag(
        find.byKey(const ValueKey('output volume')),
        const Offset(40, 0),
      );
      await tester.pump();
      expect(h.system.calls, contains('setVolume'));
      await tapKey(tester, 'mute');
      expect(h.system.calls, contains('setMuted true'));
    });

    testWidgets('the input tab: devices and their volume', (tester) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.sound,
        tools: audioTools(),
      );
      await settle(tester);
      await tester.tap(find.text('Input'));
      await settle(tester);
      expect(find.text('USB Microphone'), findsOneWidget);
      expect(find.text('USB'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('input volume')),
        const Offset(-40, 0),
      );
      await settle(tester);
      expect(
        h.tools.calls.where((c) => c.startsWith('audioVolume 52')),
        isNotEmpty,
      );
      await tapKey(tester, 'input mute');
      await settle(tester);
      expect(h.tools.calls, contains('audioMuted 52 true'));
    });

    testWidgets('interface sounds follow the sound service', (tester) async {
      final system = FakeSystem()..uiSounds = true;
      final h = await pumpSettings(tester, pane: PaneId.sound, system: system);
      await settle(tester);
      await tester.tap(switchIn('ui sounds'));
      await settle(tester);
      expect(h.system.calls, contains('setUiSoundsEnabled false'));
      expect(system.uiSounds, isFalse);
    });

    testWidgets('without the sound service the switch waits (#64)', (
      tester,
    ) async {
      await pumpSettings(tester, pane: PaneId.sound);
      await settle(tester);
      expect(find.byKey(const ValueKey('ui sounds')), findsNothing);
      expect(find.textContaining('#64'), findsOneWidget);
    });
  });

  testWidgets('Notifications: the apps and their banner style', (tester) async {
    final tools = FakeTools()
      ..apps = const [
        NotifyingApp(key: 'org.gnome.Nautilus', name: 'Files'),
        NotifyingApp(key: 'firefox', name: 'Firefox'),
      ];
    final h = await pumpSettings(
      tester,
      pane: PaneId.notifications,
      tools: tools,
      height: 1000,
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('app firefox')), findsOneWidget);
    await tapKey(tester, 'app org.gnome.Nautilus');
    expect(h.navigation.location.sub, SubPaneId.notificationApp);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('title'))).data,
      'Files',
    );
    await tester.tap(find.text('Stay until dismissed'));
    await tester.pump();
    Object? style() =>
        ((h.config.read('notifications')['apps'] as Map)['org.gnome.Nautilus']
            as Map)['style'];
    expect(style(), 'alerts');
    await tester.tap(switchIn('allow notifications'));
    await tester.pump();
    expect(style(), 'none');
    await tester.tap(switchIn('allow notifications'));
    await tester.pump();
    expect(style(), 'alerts');
  });

  testWidgets('Focus: Do Not Disturb goes through the daemon', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.focus);
    await tester.tap(switchIn('dnd switch'));
    await tester.pump();
    expect(h.system.calls, ['setDoNotDisturb true']);
  });
}
