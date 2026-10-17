// Kit `Apps/Settings/Row/Popup`, `Slider`, `Button`: the 552 pt row's trailing control ends
// 12 pt from its right edge (pop-up x 432 w 108, slider x 340 w 200, button ends at 540).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';

void main() {
  Rect rectOf(WidgetTester tester, Finder control, Finder row) {
    final c = tester.getRect(control.first);
    final r = tester.getRect(row.first);
    return Rect.fromLTRB(
      c.left - r.left,
      c.top - r.top,
      c.right - r.left,
      c.bottom - r.top,
    );
  }

  testWidgets('a pop-up row: the pop-up at x 432, 12 from the right', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.wifi);
    final popup = find.byType(AmalfiPopUpButton<dynamic>);
    final control = popup.evaluate().isNotEmpty
        ? popup
        : find.byWidgetPredicate((w) => w is AmalfiPopUpButton);
    final row = find.ancestor(
      of: control.first,
      matching: find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.minHeight >= 40,
      ),
    );
    final r = rectOf(tester, control, row);
    expect(r.left, 432);
    expect(r.width, 108);
    expect(552 - r.right, 12);
  });

  testWidgets('a slider row: the slider at x 340, 200 wide', (tester) async {
    await pumpSettings(tester, pane: PaneId.sound);
    final control = find.byType(AmalfiSlider);
    final row = find.ancestor(
      of: control.first,
      matching: find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.minHeight >= 40,
      ),
    );
    final r = rectOf(tester, control, row);
    expect(r.left, 340);
    expect(r.width, 200);
    expect(552 - r.right, 12);
  });

  testWidgets('a button row: the button ends 12 from the right', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.vpn);
    final control = find.byType(AmalfiPushButton);
    final row = find.ancestor(
      of: control.first,
      matching: find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.minHeight >= 40,
      ),
    );
    final r = rectOf(tester, control, row);
    expect(552 - r.right, 12);
  });
}
