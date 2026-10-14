// The files Ossido and silica-daemon read (keyboard, input, sound, power, focus), exactly as
// docs/spec/shell-config.md lists them: ranges, kept keys, and broken input.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/system/config.dart';
import 'package:silica_settings/src/system/settings_files.dart';

ConfigStore store() => ConfigStore(
  '${Directory.systemTemp.createTempSync('settings-files').path}/silica',
);

Object? file(ConfigStore c, String name) =>
    jsonDecode(File('${c.directory}/$name.json').readAsStringSync());

void main() {
  group('keyboard.json', () {
    test('repeat values are clamped to Ossido\'s ranges', () {
      final c = store()
        ..writeRepeatDelay(5)
        ..writeRepeatRate(500);
      expect(file(c, 'keyboard'), {'repeatDelay': 100, 'repeatRate': 100});
      c
        ..writeRepeatDelay(99999)
        ..writeRepeatRate(-3);
      expect(file(c, 'keyboard'), {'repeatDelay': 3000, 'repeatRate': 0});
      expect(c.savedRepeatRate, 0);
    });

    test('saved values missing or wrong are null', () {
      final c = store();
      expect(c.savedRepeatDelay, isNull);
      c
        ..write('keyboard', 'repeatDelay', 'fast')
        ..write('keyboard', 'repeatRate', null);
      expect(c.savedRepeatDelay, isNull);
      expect(c.savedRepeatRate, isNull);
    });

    test('layouts: at most four, empty removes the key, others are kept', () {
      final c = store()..write('keyboard', 'options', 'caps:escape');
      c.writeLayouts(['us', 'it', 'de(nodeadkeys)', 'fr', 'es']);
      expect(file(c, 'keyboard'), {
        'options': 'caps:escape',
        'layouts': ['us', 'it', 'de(nodeadkeys)', 'fr'],
      });
      c.writeLayouts([]);
      expect(file(c, 'keyboard'), {'options': 'caps:escape'});
      expect(c.savedLayouts, isEmpty);
    });

    test('layout ids join and split on the variant', () {
      expect(layoutId('de', 'nodeadkeys'), 'de(nodeadkeys)');
      expect(layoutId('it'), 'it');
      expect(splitLayout('de(nodeadkeys)'), ('de', 'nodeadkeys'));
      expect(splitLayout('it'), ('it', ''));
    });
  });

  group('input.json', () {
    test('one key of one device, the rest kept', () {
      final c = store()
        ..write('input', 'doubleClickMs', 400)
        ..writePointer(PointerDevice.mouse, 'naturalScroll', true)
        ..writePointer(PointerDevice.touchpad, 'tapToClick', true)
        ..writePointerSpeed(PointerDevice.mouse, 0.456)
        ..writeScrollSpeed(PointerDevice.touchpad, 25);
      expect(file(c, 'input'), {
        'doubleClickMs': 400,
        'mouse': {'naturalScroll': true, 'speed': 0.46},
        'touchpad': {'tapToClick': true, 'scrollSpeed': 10.0},
      });
      c.writePointer(PointerDevice.mouse, 'naturalScroll', null);
      expect((file(c, 'input') as Map)['mouse'], {'speed': 0.46});
    });

    test('a value that is not a number writes nothing', () {
      final c = store();
      expect(c.writePointerSpeed(PointerDevice.mouse, double.nan), isFalse);
      expect(c.writeScrollSpeed(PointerDevice.mouse, double.infinity), isFalse);
      expect(c.writeAlertVolume(double.nan), isFalse);
      expect(c.read('input'), isEmpty);
      expect(c.read('sound'), isEmpty);
    });

    test('reads fall back to the defaults', () {
      final c = store()..write('input', 'mouse', 'broken');
      expect(c.pointerSpeed(PointerDevice.mouse), 0);
      expect(c.pointerScrollSpeed(PointerDevice.touchpad), 1);
      expect(
        c.pointerFlag(
          PointerDevice.touchpad,
          'disableWhileTyping',
          fallback: true,
        ),
        isTrue,
      );
      c.writePointer(PointerDevice.mouse, 'speed', 7);
      expect(c.pointerSpeed(PointerDevice.mouse), 1);
    });
  });

  test('sound.json and power.json keep their other keys', () {
    final c = store()
      ..write('sound', 'uiSounds', false)
      ..writeAlertVolume(1.7)
      ..write('power', 'preventSleep', true)
      ..writeIdleMinutes('sleepMinutes', 30)
      ..writeIdleMinutes('displayOffMinutes', -5);
    expect(file(c, 'sound'), {'uiSounds': false, 'alertVolume': 1.0});
    expect(file(c, 'power'), {
      'preventSleep': true,
      'sleepMinutes': 30,
      'displayOffMinutes': 0,
    });
    expect(c.idleMinutes('sleepMinutes'), 30);
    expect(c.idleMinutes('displayOffMinutes'), 0);
    expect(c.alertVolume, 1);
  });

  group('focus.json', () {
    test('ids come from the name and never repeat or take dnd', () {
      expect(FocusMode.idFor('Deep Work!', []), 'deep-work');
      expect(FocusMode.idFor('Work', ['work', 'work-2']), 'work-3');
      expect(FocusMode.idFor('DND', []), 'focus');
      expect(FocusMode.idFor('日本', []), 'focus');
    });

    test('modes are written whole and `active` is kept', () {
      final c = store()..write('focus', 'active', 'work');
      c.writeFocusModes([
        const FocusMode(
          id: 'work',
          name: 'Work',
          symbol: 'person',
          allowedApps: ['firefox'],
          allowedPeople: ['Ada'],
        ),
      ]);
      expect(file(c, 'focus'), {
        'active': 'work',
        'modes': [
          {
            'id': 'work',
            'name': 'Work',
            'symbol': 'person',
            'allowedApps': ['firefox'],
            'allowedPeople': ['Ada'],
          },
        ],
      });
      expect(c.focusModes.single.allowedPeople, ['Ada']);
    });

    test('a broken, reserved or repeated mode is skipped; 32 at most', () {
      final c = store()
        ..write('focus', 'modes', [
          'nope',
          {'name': 'No id'},
          {'id': 'dnd', 'name': 'Reserved'},
          {
            'id': 'a',
            'name': 'A',
            'allowedApps': [1, 'x', ''],
          },
          {'id': 'a', 'name': 'Again'},
          {'id': 'b'},
        ]);
      final modes = c.focusModes;
      expect([for (final m in modes) m.id], ['a', 'b']);
      expect(modes.first.allowedApps, ['x']);
      expect(modes.last.name, 'b');
      expect(modes.last.symbol, 'moon');
      c.writeFocusModes([
        for (var i = 0; i < 40; i++) FocusMode(id: 'm$i', name: 'M$i'),
      ]);
      expect(c.focusModes, hasLength(32));
    });
  });
}
