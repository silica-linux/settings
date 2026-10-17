import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/src/system/dbus.dart';
import 'package:silica_settings/src/system/system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DBus.channel, (call) async {
          switch (call.method) {
            case 'call':
              return [<String, Object?>{}];
            case 'subscribe':
              return 1;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DBus.channel, null);
  });

  test('a listener that arrives after the first one gets the snapshot', () async {
    final backend = DaemonBackend();
    final seen = <SystemState>[];
    final keep = backend.states.listen(seen.add);
    while (seen.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(seen.single.reachable, isTrue);

    // The snapshot was read for the first listener; a pane opened now must get it too.
    final later = await backend.states.first.timeout(
      const Duration(seconds: 2),
    );
    expect(later.reachable, isTrue);
    await keep.cancel();
  });
}
