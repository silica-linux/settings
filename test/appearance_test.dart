// Appearance against the fake daemon and a temporary theme.json.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/services.dart';
import 'package:silica_settings/src/style.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Appearance', () {
    testWidgets('Dark goes through the daemon; Automatic waits (#58)', (
      tester,
    ) async {
      final h = await pumpSettings(tester);
      await tapKey(tester, 'mode dark');
      expect(h.system.calls, ['setDark true']);
      await tapKey(tester, 'mode automatic');
      expect(h.system.calls, ['setDark true']);
      expect(find.textContaining('#58'), findsOneWidget);
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
