// Keyboard, Users, Printers, the panes waiting for a backend, and every pane building.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

void main() {
  group('Keyboard (#73)', () {
    testWidgets('the sliders start from the session and write keyboard.json', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.keyboard,
        extraEnv: const {'OSSIDO_KEY_REPEAT': '250,30'},
      );
      SilicaSlider slider(String key) =>
          tester.widget<SilicaSlider>(find.byKey(ValueKey(key)));
      // 30 per second and 250 ms are the steps 6 and 5 of the sliders.
      expect(slider('repeat rate').value, 6);
      expect(slider('repeat delay').value, 5);
      expect(slider('repeat rate').onChanged, isNotNull);
      expect(h.config.read('keyboard'), isEmpty);
      await tester.drag(
        find.byKey(const ValueKey('repeat rate')),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard')['repeatRate'], 0);
      await tester.drag(
        find.byKey(const ValueKey('repeat delay')),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard')['repeatDelay'], 1500);
      expect(slider('repeat delay').value, 0);
      // The other keys of the file are kept.
      h.config.write('keyboard', 'options', 'caps:escape');
      await tester.drag(
        find.byKey(const ValueKey('repeat rate')),
        const Offset(400, 0),
      );
      await tester.pump();
      expect(h.config.read('keyboard'), {
        'repeatRate': 40,
        'repeatDelay': 1500,
        'options': 'caps:escape',
      });
    });

    testWidgets('input sources: add a layout and a variant, remove, at most 4', (
      tester,
    ) async {
      final h = await pumpSettings(
        tester,
        pane: PaneId.keyboard,
        tools: FakeTools()..layouts = const ['us', 'it', 'de', 'fr'],
      );
      await settle(tester);
      expect(find.text('System default'), findsOneWidget);
      await tapRowButton(tester, 'input sources');
      expect(find.byKey(const ValueKey('source default')), findsOneWidget);
      // Chooses [layout] (and [variant] when it has some) in the pop-up sheets.
      Future<void> add(String layout, [String? variant]) async {
        await tapKey(tester, 'add source');
        await settle(tester);
        await tapKey(tester, 'choice $layout');
        await tapKey(tester, 'choice done');
        await tester.pump(const Duration(seconds: 1));
        await settle(tester);
        if (variant != null) {
          await tapKey(tester, 'choice $variant');
          await tapKey(tester, 'choice done');
          await tester.pump(const Duration(seconds: 1));
          await settle(tester);
        }
      }

      await add('it');
      expect(h.config.read('keyboard')['layouts'], ['it']);
      await add('de', 'nodeadkeys');
      expect(h.config.read('keyboard')['layouts'], ['it', 'de(nodeadkeys)']);
      expect(find.text('German (no dead keys)'), findsOneWidget);
      await tapKey(tester, 'remove source it');
      expect(h.config.read('keyboard')['layouts'], ['de(nodeadkeys)']);
      // Four is the most: the fourth source disables Add.
      await add('us');
      await add('fr');
      await add('it');
      expect(h.config.read('keyboard')['layouts'], [
        'de(nodeadkeys)',
        'us',
        'fr',
        'it',
      ]);
      expect(
        tester
            .widget<SilicaButton>(find.byKey(const ValueKey('add source')))
            .onPressed,
        isNull,
      );
      for (final id in ['de(nodeadkeys)', 'us', 'fr', 'it']) {
        await tapKey(tester, 'remove source $id');
      }
      expect(h.config.read('keyboard').containsKey('layouts'), isFalse);
    });
  });

  testWidgets('Keyboard: the shortcuts sheet lists Silica bindings', (
    tester,
  ) async {
    await pumpSettings(tester, pane: PaneId.keyboard);
    await tapKey(tester, 'shortcuts');
    expect(find.text('Logo ⇧ 3'), findsOneWidget);
    await tapKey(tester, 'shortcut category 2');
    expect(find.text('Logo Space'), findsOneWidget);
  });

  testWidgets('Users & Groups lists the accounts', (tester) async {
    final tools = FakeTools()
      ..accounts = const [
        UserAccount(login: 'bob', name: 'Bob', uid: 1001, admin: false),
        UserAccount(login: 'ada', name: 'Ada Lovelace', uid: 1000, admin: true),
      ];
    await pumpSettings(tester, pane: PaneId.users, tools: tools);
    await settle(tester);
    expect(find.text('ada · Admin'), findsOneWidget);
    expect(find.text('bob · Standard'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('current user'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('user bob'))).dy),
    );
  });

  testWidgets('Printers: the CUPS printers and the default one', (
    tester,
  ) async {
    final runs = <String>[];
    await pumpSettings(
      tester,
      pane: PaneId.printers,
      run: (exe, args) async {
        runs.add('$exe ${args.join(' ')}');
        return switch (exe) {
          'lpstat' =>
            'printer Office is idle.\nprinter Home is idle.\n'
                'system default destination: Office\n',
          'lpoptions' => '',
          _ => null,
        };
      },
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('printer Home')), findsOneWidget);
    await choose(tester, 'default printer', 'Home');
    await settle(tester);
    expect(runs, contains('lpoptions -d Home'));
  });

  for (final pane in [
    PaneId.screenTime,
    PaneId.lockScreen,
    PaneId.privacy,
    PaneId.password,
    PaneId.internetAccounts,
    PaneId.mouse,
    PaneId.accessibility,
    PaneId.search,
  ]) {
    testWidgets('${pane.name}: waits for its backend and names the issue', (
      tester,
    ) async {
      final h = await pumpSettings(tester, pane: pane, height: 1300);
      expect(find.byKey(const ValueKey('unavailable')), findsWidgets);
      expect(find.textContaining('silica-linux/settings#'), findsWidgets);
      // Nothing reaches the system from these panes.
      for (final s in find.byType(SilicaSwitch).evaluate()) {
        await tester.tap(find.byWidget(s.widget), warnIfMissed: false);
      }
      await tester.pump();
      expect(h.system.calls, isEmpty);
      expect(h.tools.calls, isEmpty);
      expect(h.config.read('lockscreen'), isEmpty);
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
        h.navigation.openSub(sub, 'app\u001fApp');
        await tester.pump();
        expect(tester.takeException(), isNull, reason: sub.name);
        h.navigation.openPane(PaneId.general);
        await tester.pump();
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
