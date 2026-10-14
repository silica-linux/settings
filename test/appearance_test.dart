// Appearance against the fake daemon and a temporary theme.json.

import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/services.dart';
import 'package:silica_settings/src/style.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Appearance', () {
    testWidgets('light, dark and automatic go through the daemon (#58)', (
      tester,
    ) async {
      final h = await pumpSettings(tester);
      await tapKey(tester, 'mode dark');
      await tapKey(tester, 'mode automatic');
      await tapKey(tester, 'mode light');
      expect(h.system.calls, [
        'setAppearanceMode dark',
        'setAppearanceMode auto',
        'setAppearanceMode light',
      ]);
      expect(find.textContaining('#58'), findsNothing);
      expect(find.textContaining('sunset'), findsOneWidget);
    });

    testWidgets('the daemon\'s mode is the one chosen', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await pumpSettings(
        tester,
        system: FakeSystem(
          const SystemState(
            reachable: true,
            dark: true,
            appearanceMode: 'auto',
          ),
        ),
      );
      bool selected(String key) =>
          tester
              .getSemantics(find.byKey(ValueKey(key)))
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(selected('mode automatic'), isTrue);
      expect(selected('mode dark'), isFalse);
      h.system.emit(const SystemState(reachable: true, dark: true));
      await tester.pump();
      await tester.pump();
      // An older daemon without a mode tells light from dark only.
      expect(selected('mode dark'), isTrue);
      expect(selected('mode automatic'), isFalse);
      semantics.dispose();
    });

    testWidgets('without the daemon nothing can be chosen', (tester) async {
      final h = await pumpSettings(
        tester,
        system: FakeSystem(const SystemState()),
      );
      await tapKey(tester, 'mode automatic');
      expect(h.system.calls, isEmpty);
      expect(find.textContaining('isn\'t running'), findsOneWidget);
    });

    testWidgets('the accent is saved and drawn by the window', (tester) async {
      final h = await pumpSettings(tester);
      await tapKey(tester, 'accent green');
      expect(h.config.text('theme', 'accent', fallback: ''), 'green');
      expect(find.text('Green'), findsOneWidget);
    });

    testWidgets('the sidebar icon size resizes the sidebar and is saved', (
      tester,
    ) async {
      final h = await pumpSettings(tester, height: 1000);
      double pitch() =>
          tester.getTopLeft(find.byKey(const ValueKey('pane bluetooth'))).dy -
          tester.getTopLeft(find.byKey(const ValueKey('pane wifi'))).dy;
      expect(pitch(), SettingsMetrics.rowPitch);
      await choose(tester, 'sidebar icon size', 'Large');
      expect(h.config.text('theme', 'sidebarIconSize', fallback: ''), 'large');
      expect(pitch(), greaterThan(SettingsMetrics.rowPitch));
    });

    testWidgets('scroll bars: always keeps the track, saved in theme.json', (
      tester,
    ) async {
      final h = await pumpSettings(tester, height: 1200);
      await tester.tap(find.text('Always'));
      await tester.pump();
      expect(h.services.scrollBars.value, ScrollBarsMode.always);
      expect(h.config.text('theme', 'scrollBars', fallback: ''), 'always');
      expect(find.byType(SilicaScrollbar), findsWidgets);
    });
  });
}
