import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/style.dart';
import 'package:silica_settings/src/system/system.dart';
import 'package:silica_settings/src/ui/symbol.dart';

import 'fakes.dart';

String title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('title'))).data ?? '';

void main() {
  testWidgets('the sidebar lists the panes in order, in blocks', (
    tester,
  ) async {
    await pumpSettings(tester, height: 1300);
    final names = [
      for (final pane in paneGroups(hasBattery: false).expand((g) => g))
        pane.name,
    ];
    final tops = [
      for (final name in names)
        tester.getTopLeft(find.byKey(ValueKey('pane $name'))).dy,
    ];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: names[i]);
    }
    // Rows 32 apart inside a block, 13 more between blocks (ST-NAV-02).
    expect(tops[1] - tops[0], SettingsMetrics.rowPitch);
    expect(
      tops[5] - tops[4],
      SettingsMetrics.rowPitch + SettingsMetrics.groupGap,
    );
  });

  testWidgets('the measured sidebar: search, rows and selection', (
    tester,
  ) async {
    await pumpSettings(tester);
    // The search field: 220 × 28 at (10, 60).
    final search = find.byKey(const ValueKey('sidebar search'));
    expect(tester.getTopLeft(search), const Offset(10, 60));
    expect(tester.getSize(search), const Size(220, 28));
    // The rows start at 156; the row spans the sidebar, the capsule is 228 wide at x 6.
    final wifi = find.byKey(const ValueKey('pane wifi'));
    expect(tester.getTopLeft(wifi).dy, SettingsMetrics.paneListTop);
    expect(tester.getSize(wifi).width, SettingsMetrics.sidebarWidth);
    final capsule = find
        .descendant(
          of: find.byKey(const ValueKey('pane appearance')),
          matching: find.byType(DecoratedBox),
        )
        .first;
    expect(tester.getSize(capsule), const Size(228, 32));
    expect(tester.getTopLeft(capsule).dx, 6);
    // The back / forward capsule at (248, 8), 73 × 36; the title 12 after it.
    final nav = find.byKey(const ValueKey('nav'));
    expect(tester.getTopLeft(nav), const Offset(248, 8));
    expect(tester.getSize(nav).height, 36);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('title'))).dx,
      248 + 73 + 4 + 12,
    );
    // The window's content starts at x 240; the divider is the 1 pt line at x 239.
    expect(SettingsMetrics.sidebarWidth, 240);
  });

  testWidgets('the sidebar rows and the account cell match the kit masters', (
    tester,
  ) async {
    await pumpSettings(tester);
    // The 24 pt tile at x 10 (y 4 in the row), the label at x 44; the blocks 12 apart on
    // top of the 32 pt pitch.
    final row = find.byKey(const ValueKey('pane wifi'));
    final tile = find.descendant(of: row, matching: find.byType(IconTile));
    expect(tester.getTopLeft(tile), const Offset(10, 156 + 4));
    expect(tester.getSize(tile), const Size(24, 24));
    expect(
      tester
          .getTopLeft(find.descendant(of: row, matching: find.text('Wi-Fi')))
          .dx,
      44,
    );
    final general = tester.getTopLeft(
      find.byKey(const ValueKey('pane general')),
    );
    expect(general.dy, 156 + 5 * 32 + 12);
    // `Account avatar`: 36 at (12, 100), the name at x 60.
    final cell = find.byKey(const ValueKey('account cell'));
    expect(tester.getTopLeft(cell).dy, 100);
    expect(tester.getSize(cell).height, 36);
    expect(tester.getTopLeft(find.text('Local account')).dx, 60);
  });

  testWidgets('the measured grouped list: inset 20, rows 52 (kit General)', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.general);
    final about = find.byKey(const ValueKey('general about'));
    expect(tester.getSize(about), const Size(552, 52));
    expect(tester.getTopLeft(about).dx, 260);
    // The header under the toolbar: the 64 pt tile 16 below it, the first group at y 240.
    expect(tester.getTopLeft(about).dy, 240);
  });

  testWidgets('a click switches the pane in one frame, and back and forward '
      'return', (tester) async {
    final h = await pumpSettings(tester);
    expect(title(tester), 'Appearance');
    await tester.tap(find.byKey(const ValueKey('pane wifi')));
    await tester.pump();
    expect(title(tester), 'Wi-Fi');
    // The capsule's two 36 pt segments: back at x 248, forward at x 285.
    await tester.tapAt(const Offset(248 + 18, 26));
    await tester.pump();
    expect(title(tester), 'Appearance');
    expect(h.navigation.canGoForward, isTrue);
    await tester.tapAt(const Offset(248 + 54, 26));
    await tester.pump();
    expect(title(tester), 'Wi-Fi');
  });

  testWidgets('Logo-[ goes back', (tester) async {
    final h = await pumpSettings(tester);
    h.navigation.openPane(PaneId.sound);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(title(tester), 'Appearance');
  });

  testWidgets('search lists two-line results and Esc brings the panes back', (
    tester,
  ) async {
    final h = await pumpSettings(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar search')),
        matching: find.byType(EditableText),
      ),
      'repeat',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('pane wifi')), findsNothing);
    final result = find.byKey(
      const ValueKey('result Key repeat rate keyboard'),
    );
    expect(result, findsOneWidget);
    expect(
      find.descendant(of: result, matching: find.text('Keyboard')),
      findsOneWidget,
    );
    await tester.tap(result);
    await tester.pump();
    expect(title(tester), 'Keyboard');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(h.navigation.query, '');
    expect(find.byKey(const ValueKey('pane wifi')), findsOneWidget);
  });

  testWidgets('a search without matches says so', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar search')),
        matching: find.byType(EditableText),
      ),
      'zzzz',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('no results')), findsOneWidget);
  });

  testWidgets('a machine with a battery shows Battery instead of Energy', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      system: FakeSystem(
        const SystemState(
          reachable: true,
          batteryPresent: true,
          batteryPercent: 80,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('pane battery')), findsOneWidget);
    expect(find.byKey(const ValueKey('pane energy')), findsNothing);
  });

  testWidgets('the account cell shows the user and opens Users & Groups', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('account cell')));
    await tester.pump();
    expect(title(tester), 'Users & Groups');
  });

  testWidgets('Italian follows the system language', (tester) async {
    await pumpSettings(tester, locale: const Locale('it'));
    expect(title(tester), 'Aspetto');
    expect(find.text('Scrivania e Dock'), findsOneWidget);
  });

  testWidgets('dark: the content takes the measured background', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpSettings(tester);
    final boxes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((b) => b.color)
        .toList();
    expect(boxes, contains(SettingsColors.darkColors.content));
    expect(boxes, contains(SettingsColors.darkColors.sidebar));
  });
}
