// Desktop & Dock, Menu Bar, Displays and Wallpaper: the shell's files and the tools.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Desktop & Dock', () {
    testWidgets('the switches write dock.json', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      for (final (key, option, value) in [
        ('dock magnify', 'magnify', true),
        ('dock autohide', 'autohide', true),
        ('dock indicators', 'indicators', false),
        ('dock recents', 'recents', true),
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(switchIn(key));
        await tester.pump();
        expect(h.config.flag('dock', option, fallback: !value), value);
      }
    });

    testWidgets('the minimize effect and the position', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock minimize effect', 'Scale effect');
      expect(h.config.text('dock', 'minimizeEffect', fallback: ''), 'scale');
      // The side Docks are not drawn yet: Left cannot be chosen.
      await choose(tester, 'dock position', 'Left');
      expect(h.config.text('dock', 'position', fallback: 'none'), 'none');
    });

    testWidgets('the default web browser goes through xdg-settings', (
      tester,
    ) async {
      final tools = FakeTools()
        ..browserList = const [
          AppEntry(id: 'firefox.desktop', name: 'Firefox'),
          AppEntry(id: 'chromium.desktop', name: 'Chromium'),
        ]
        ..browser = 'firefox.desktop';
      final h = await pumpSettings(
        tester,
        pane: PaneId.desktopDock,
        tools: tools,
        height: 1200,
      );
      await settle(tester);
      await choose(tester, 'default browser', 'Chromium');
      await settle(tester);
      expect(h.tools.calls, contains('browser chromium.desktop'));
    });

    testWidgets('the hot corners sheet opens and closes', (tester) async {
      await pumpSettings(tester, pane: PaneId.desktopDock, height: 1300);
      await tapKey(tester, 'hot corners');
      expect(find.byKey(const ValueKey('hot corners done')), findsOneWidget);
      await tapKey(tester, 'hot corners done');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('hot corners done')), findsNothing);
    });
  });

  testWidgets('Menu Bar: the status items write menubar.json', (tester) async {
    final h = await pumpSettings(tester, pane: PaneId.menuBar);
    Finder check(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(SilicaCheckbox),
    );
    await tester.tap(check('menubar bluetooth'));
    await tester.pump();
    expect(h.config.flag('menubar', 'bluetooth', fallback: false), isTrue);
    await choose(tester, 'menubar sound', 'Always show');
    expect(h.config.text('menubar', 'sound', fallback: ''), 'always');
    await tester.tap(check('menubar sound'));
    await tester.pump();
    expect(h.config.text('menubar', 'sound', fallback: ''), 'never');
    await tester.tap(switchIn('menubar battery percent'));
    await tester.pump();
    expect(h.config.flag('menubar', 'batteryPercent', fallback: false), isTrue);
  });

  testWidgets(
    'Displays: without the compositor the machine\'s modes, read-only',
    (tester) async {
      final tools = FakeTools()
        ..outputs = const [
          DisplayOutput(
            connector: 'HDMI-A-1',
            modes: ['2560x1440', '1920x1080'],
          ),
        ];
      await pumpSettings(tester, pane: PaneId.displays, tools: tools);
      await settle(tester);
      expect(find.text('HDMI-A-1'), findsOneWidget);
      expect(find.text('2560 × 1440 (native)'), findsOneWidget);
      expect(find.text('1920 × 1080'), findsOneWidget);
      expect(find.textContaining('compositor didn’t report'), findsOneWidget);
    },
  );

  testWidgets('Wallpaper: a colour replaces the choice in wallpaper.json', (
    tester,
  ) async {
    final h = await pumpSettings(tester, pane: PaneId.wallpaper);
    await tapKey(tester, 'wallpaper {color: #1f2a44}');
    expect(h.config.read('wallpaper'), {'color': '#1f2a44'});
    await tapKey(tester, 'wallpaper {}');
    expect(h.config.read('wallpaper'), isEmpty);
  });
}
