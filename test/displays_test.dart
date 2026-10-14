// Displays against the fake daemon: resolution, refresh rate, scale and rotation with the
// "Keep these settings?" revert, and the night light.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/displays.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/ui/popup.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

const _native = OutputMode(
  width: 2560,
  height: 1440,
  refresh: 59.95,
  preferred: true,
);
const _fast = OutputMode(width: 2560, height: 1440, refresh: 144);
const _full = OutputMode(width: 1920, height: 1080, refresh: 60);
const _small = OutputMode(width: 1280, height: 720, refresh: 60);

OutputInfo panel({bool enabled = true}) => OutputInfo(
  connector: 'eDP-1',
  identity: 'ACME Panel 1 ABC',
  make: 'ACME',
  model: 'Panel 1',
  modes: const [_native, _fast, _full, _small],
  current: _native,
  enabled: enabled,
  primary: true,
);

FakeSystem daemonWith(List<OutputInfo> displays) =>
    FakeSystem(const SystemState(reachable: true))..displays = displays;

Future<Harness> open(
  WidgetTester tester,
  FakeSystem system, {
  double height = 900,
}) async {
  final h = await pumpSettings(
    tester,
    system: system,
    pane: PaneId.displays,
    height: height,
  );
  await settle(tester);
  return h;
}

/// Lets the sheet leave and the pending futures run.
Future<void> afterSheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 1));
  await settle(tester);
}

void main() {
  group('Displays (#63)', () {
    testWidgets('the compositor\'s displays and their current mode', (
      tester,
    ) async {
      await open(tester, daemonWith([panel()]));
      expect(find.text('Panel 1'), findsOneWidget);
      expect(find.text('2560 × 1440 (native)'), findsOneWidget);
      expect(find.text('59.95 Hz'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.textContaining('compositor didn’t report'), findsNothing);
    });

    testWidgets('a resolution is kept when Keep is pressed', (tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      await choose(tester, 'display resolution', '1920 × 1080');
      await settle(tester);
      expect(system.calls, ['configureOutput eDP-1 1920x1080@60.0']);
      expect(find.text('Keep these display settings?'), findsOneWidget);
      expect(find.textContaining('15 seconds'), findsOneWidget);
      await tapKey(tester, 'keep display');
      await afterSheet(tester);
      // No second call: the new mode stays, and the pane shows it.
      expect(system.calls, hasLength(1));
      expect(find.text('1920 × 1080'), findsOneWidget);
    });

    testWidgets('Revert puts the display back as it was', (tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      await choose(tester, 'display scale', '2×');
      await settle(tester);
      expect(system.calls, ['configureOutput eDP-1 scale 2.0']);
      await tapKey(tester, 'revert display');
      await afterSheet(tester);
      expect(
        system.calls.last,
        'configureOutput eDP-1 2560x1440@59.95 scale 1.0 normal',
      );
      expect(system.displays.single.scale, 1);
      expect(find.text('1×'), findsOneWidget);
    });

    testWidgets('without an answer in 15 seconds the display goes back', (
      tester,
    ) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      await choose(tester, 'display rotation', '90°');
      await settle(tester);
      expect(system.calls, ['configureOutput eDP-1 90']);
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('10 seconds'), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
      expect(system.calls, hasLength(1));
      expect(find.text('Keep these display settings?'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await afterSheet(tester);
      expect(
        system.calls.last,
        'configureOutput eDP-1 2560x1440@59.95 scale 1.0 normal',
      );
      expect(system.displays.single.transform, 'normal');
    });

    testWidgets('the refresh rate keeps the resolution', (tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      await choose(tester, 'display refresh', '144 Hz');
      await settle(tester);
      expect(system.calls, ['configureOutput eDP-1 2560x1440@144.0']);
      await tapKey(tester, 'keep display');
      await afterSheet(tester);
      expect(find.text('144 Hz'), findsOneWidget);
    });

    testWidgets('a refusal says why and asks nothing', (tester) async {
      final system = daemonWith([panel()])..displayError = 'no 1280x720 mode';
      await open(tester, system);
      await choose(tester, 'display resolution', '1280 × 720');
      await settle(tester);
      expect(find.text('Keep these display settings?'), findsNothing);
      expect(find.textContaining('no 1280x720 mode'), findsOneWidget);
      expect(system.calls, hasLength(1));
    });

    testWidgets('a display that is not in use cannot be changed yet', (
      tester,
    ) async {
      final system = daemonWith([panel(enabled: false)]);
      await open(tester, system);
      expect(find.textContaining('Only the display in use'), findsOneWidget);
      final resolution = tester.widget<FormPopUp<String>>(
        find.descendant(
          of: find.byKey(const ValueKey('display resolution')),
          matching: find.byType(FormPopUp<String>),
        ),
      );
      expect(resolution.onChanged, isNull);
      expect(system.calls, isEmpty);
    });

    testWidgets('the displays in the state replace the list', (tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      system.displays = [
        panel(),
        const OutputInfo(connector: 'HDMI-A-1', modes: [_full], current: _full),
      ];
      system.emit(system.withDisplays);
      await tester.pump();
      await tester.pump();
      expect(find.text('HDMI-A-1'), findsOneWidget);
      await tapKey(tester, 'display HDMI-A-1');
      await settle(tester);
      expect(find.text('1920 × 1080 (native)'), findsNothing);
      expect(find.text('1920 × 1080'), findsWidgets);
    });
  });

  group('Night light (#63)', () {
    Future<FakeSystem> opened(WidgetTester tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      await tapRowButton(tester, 'night light');
      await settle(tester);
      return system;
    }

    testWidgets('turn it on, choose a schedule and its times', (tester) async {
      final system = await opened(tester);
      expect(find.text('Off'), findsWidgets);
      await tester.tap(switchIn('night enabled'));
      await settle(tester);
      expect(system.calls, ['setNightLight enabled true']);
      await choose(tester, 'night schedule', 'Custom');
      await settle(tester);
      expect(system.calls.last, 'setNightLight schedule custom');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('night from')),
          matching: find.byType(EditableText),
        ),
        '22:30',
      );
      await settle(tester);
      expect(system.calls.last, 'setNightLight from 22:30');
      // Not a time: nothing is sent and the hint appears.
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('night to')),
          matching: find.byType(EditableText),
        ),
        '25:99',
      );
      await settle(tester);
      expect(system.calls.last, 'setNightLight from 22:30');
      expect(find.textContaining('24-hour'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('night to')),
          matching: find.byType(EditableText),
        ),
        '06:45',
      );
      await settle(tester);
      expect(system.calls.last, 'setNightLight to 06:45');
      expect(find.textContaining('24-hour'), findsNothing);
    });

    testWidgets('sunset to sunrise and the temperature', (tester) async {
      final system = await opened(tester);
      await choose(tester, 'night schedule', 'Sunset to sunrise');
      await settle(tester);
      expect(system.calls.last, 'setNightLight schedule sunset');
      // Only the end of the drag is sent; fully to the warm end is 1900 K.
      await tester.drag(
        find.descendant(
          of: find.byKey(const ValueKey('night temperature')),
          matching: find.byType(SilicaSlider),
        ),
        const Offset(500, 0),
      );
      await settle(tester);
      expect(system.calls.where((c) => c.contains('temperature')), [
        'setNightLight temperature 1900',
      ]);
    });

    testWidgets('a refusal is said in the sheet', (tester) async {
      final system = await opened(tester);
      system.displayError = 'night light: enabled, temperature 1900–6500';
      await tester.tap(switchIn('night enabled'));
      await settle(tester);
      expect(find.textContaining('temperature 1900'), findsOneWidget);
    });

    testWidgets('the button says what it is set to', (tester) async {
      final system = daemonWith([panel()]);
      await open(tester, system);
      expect(find.text('Off'), findsOneWidget);
      system.night = const NightLight(
        enabled: true,
        schedule: 'custom',
        from: '22:00',
        to: '06:30',
      );
      system.emit(system.withDisplays);
      await tester.pump();
      await tester.pump();
      expect(find.text('22:00 to 06:30'), findsOneWidget);
    });
  });

  test('the displays JSON of the daemon is read leniently', () {
    final list = OutputInfo.parseList(
      '[{"connector":"eDP-1","identity":"A B","model":"B","scale":1.5,'
      '"transform":"90","enabled":true,"primary":true,"widthMm":300,'
      '"modes":[{"width":2560,"height":1440,"refresh":59.95,"preferred":true},'
      '{"width":1920,"height":1080,"refresh":60},{"width":0,"height":1}],'
      '"current":{"width":2560,"height":1440,"refresh":59.95}},'
      '{"connector":""},3]',
    );
    expect(list, hasLength(1));
    final d = list.single;
    expect(d.name, 'B');
    expect(d.scale, 1.5);
    expect(d.transform, '90');
    expect(d.modes, hasLength(2));
    expect(d.sizes.first.size, '2560x1440');
    expect(d.refreshesAt('2560x1440'), [59.95]);
    expect(OutputInfo.parseList('not json'), isEmpty);
    expect(OutputInfo.parseList('{"a":1}'), isEmpty);
    expect(OutputInfo.parseList(''), isEmpty);
  });

  test('the night light state of the daemon is read with its limits', () {
    final state = SystemState.fromDict({
      'nightlight.enabled': true,
      'nightlight.temperature': 99999,
      'nightlight.schedule': 'sometimes',
      'nightlight.from': '7pm',
      'nightlight.to': '06:30',
      'nightlight.active': true,
    });
    expect(state.night.enabled, isTrue);
    expect(state.night.temperature, 6500);
    expect(state.night.schedule, 'off');
    expect(state.night.from, '21:00');
    expect(state.night.to, '06:30');
    expect(state.night.active, isTrue);
    expect(SystemState.fromDict({}).night.temperature, 3400);
  });
}
