// The JSON Settings writes for the shell, exactly as docs/spec/shell-config.md lists it.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/model/panes.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/shell_config.dart';
import 'package:silica_ui/silica_ui.dart';

import 'fakes.dart';
import 'pane_helpers.dart';

ConfigStore store() => ConfigStore(
  '${Directory.systemTemp.createTempSync('shell-config').path}/silica',
);

Object? file(ConfigStore c, String name) =>
    jsonDecode(File('${c.directory}/$name.json').readAsStringSync());

void main() {
  group('keys not wired yet', () {
    test(
      'dock.json sizes are clamped and the magnified one follows the tile',
      () {
        final c = store()..writeDockSizes(tile: 64, magnified: 90);
        expect(file(c, 'dock'), {'tileSize': 64, 'magnifiedSize': 90});
        c.writeDockSizes(tile: 500, magnified: 1);
        expect(file(c, 'dock'), {'tileSize': 128, 'magnifiedSize': 128});
        c.writeDockSizes(tile: 48, magnified: 1000);
        expect((file(c, 'dock') as Map)['magnifiedSize'], 100);
      },
    );

    test('dock.json launchAnimation and minimizeToApp keep the other keys', () {
      final c = store()
        ..write('dock', 'magnify', false)
        ..writeLaunchAnimation(LaunchAnimation.none)
        ..writeMinimizeToApp(true);
      expect(file(c, 'dock'), {
        'magnify': false,
        'launchAnimation': 'none',
        'minimizeToApp': true,
      });
    });

    test('menubar.json autohide, background, recentItems and clock', () {
      final c = store()
        ..write('menubar', 'battery', true)
        ..writeMenuBarAutohide(MenuBarAutohide.always)
        ..writeMenuBarBackground(false)
        ..writeRecentItems(15)
        ..writeClock(const ClockStyle(hour24: true, seconds: true));
      expect(file(c, 'menubar'), {
        'battery': true,
        'autohide': 'always',
        'background': false,
        'recentItems': 15,
        'clock': {
          'hour24': true,
          'seconds': true,
          'weekday': true,
          'date': 'auto',
        },
      });
      // Following the system language writes no hour24; a count off the list is 10.
      c
        ..writeClock(const ClockStyle(date: ClockDate.never))
        ..writeRecentItems(7);
      final menubar = file(c, 'menubar') as Map;
      expect(menubar['clock'], {
        'seconds': false,
        'weekday': true,
        'date': 'never',
      });
      expect(menubar['recentItems'], 10);
    });

    test('notifications.json defaults and per-app keys', () {
      final c = store()
        ..writeAppNotification('firefox', 'style', 'alerts')
        ..writeNotificationDefaults(
          previews: PreviewMode.unlocked,
          grouping: GroupingMode.byApp,
        )
        ..writeAppNotification('firefox', 'badges', false)
        ..writeAppNotification('firefox', 'sound', false)
        ..writeAppNotification('firefox', 'previews', 'never');
      expect(file(c, 'notifications'), {
        'apps': {
          'firefox': {
            'style': 'alerts',
            'badges': false,
            'sound': false,
            'previews': 'never',
          },
        },
        'previews': 'unlocked',
        'grouping': 'byApp',
      });
      c.writeAppNotification('firefox', 'previews', null);
      expect(
        ((file(c, 'notifications') as Map)['apps'] as Map)['firefox'],
        isNot(contains('previews')),
      );
    });

    test('wallpaper.json fit sits beside the color or image', () {
      final c = store()
        ..replace('wallpaper', {'image': '/a.png'})
        ..writeWallpaperFit(WallpaperFit.fit);
      expect(file(c, 'wallpaper'), {'image': '/a.png', 'fit': 'fit'});
    });
  });

  group('keys written today', () {
    testWidgets('dock.json', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.desktopDock);
      await choose(tester, 'dock minimize effect', 'Scale effect');
      for (final key in ['dock magnify', 'dock autohide', 'dock indicators']) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(switchIn(key));
        await tester.pump();
      }
      expect(file(h.config, 'dock'), {
        'minimizeEffect': 'scale',
        'magnify': false,
        'autohide': true,
        'indicators': false,
      });
    });

    testWidgets('menubar.json', (tester) async {
      final h = await pumpSettings(tester, pane: PaneId.menuBar);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('menubar bluetooth')),
          matching: find.byType(SilicaCheckbox),
        ),
      );
      await tester.pump();
      expect(file(h.config, 'menubar'), {'bluetooth': true});
    });
  });
}
