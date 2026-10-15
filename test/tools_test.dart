// The parsers of the system tools, on sample outputs of nmcli, wpctl, timedatectl, localectl,
// BlueZ, passwd and pci.ids, and the commands the real tools run.

import 'package:flutter_test/flutter_test.dart';
import 'package:silica_settings/l10n/gen/app_localizations_en.dart';
import 'package:silica_settings/src/system/host.dart';
import 'package:silica_settings/src/system/tools.dart';
import 'package:silica_settings/src/system/tools_host.dart';
import 'package:silica_settings/src/ui/errors.dart';

void main() {
  test('nmcli terse fields keep escaped colons', () {
    expect(HostSystemTools.splitTerse(r'*:My\:Net:80:WPA2'), [
      '*',
      'My:Net',
      '80',
      'WPA2',
    ]);
  });

  test('access points: one per name, the strongest, the one in use first', () {
    final aps = HostSystemTools.parseAccessPoints(
      ' :Cafe:30:\n'
      ' :Home:60:WPA2\n'
      '*:Home:40:WPA2\n'
      ' ::90:WPA2\n'
      ' :Office:70:WPA1 WPA2\n'
      ' :Cafe:50:--\n',
    );
    expect(aps.map((a) => a.ssid), ['Home', 'Office', 'Cafe']);
    expect(aps.first.inUse, isTrue);
    expect(aps.first.strength, 40);
    expect(aps.last.secured, isFalse);
    expect(aps.last.strength, 50);
  });

  test('devices, connections and details', () {
    final devices = HostSystemTools.parseDevices(
      'wlp2s0:wifi:connected:Home\nenp3s0:ethernet:unavailable:\nlo:loopback:connected (externally):lo\n',
    );
    expect(devices.first.connected, isTrue);
    expect(devices[1].connected, isFalse);
    final saved = HostSystemTools.parseConnections(
      'Home:802-11-wireless:yes:yes\nWork:wireguard:no:no\n',
    );
    expect(saved.first.isWifi, isTrue);
    expect(saved.last.isVpn, isTrue);
    expect(saved.last.autoconnect, isFalse);
    final details = HostSystemTools.parseDetails(
      'GENERAL.HWADDR:AA\\:BB\\:CC\\:DD\\:EE\\:FF\n'
      'IP4.ADDRESS[1]:192.168.1.20/24\n'
      'IP4.GATEWAY:192.168.1.1\n'
      'IP4.DNS[1]:1.1.1.1\n'
      'IP6.ADDRESS[1]:fe80::1/64\n'
      'IP6.ADDRESS[2]:2001:db8::5/64\n'
      'IP6.GATEWAY:--\n',
    );
    expect(details.hardwareAddress, 'AA:BB:CC:DD:EE:FF');
    expect(details.ipv4, ['192.168.1.20/24']);
    expect(details.gateway, '192.168.1.1');
    expect(details.dns, ['1.1.1.1']);
    expect(details.ipv6, ['2001:db8::5/64']);
  });

  test('wpctl status: outputs and inputs, the default and the volume', () {
    final audio = HostSystemTools.parseWpctlStatus('''
PipeWire 'pipewire-0' [1.6.2]
 └─ Clients:
        33. WirePlumber                         [1.6.2]

Audio
 ├─ Devices:
 │      85. Raptor Lake-P/U/H cAVS              [alsa]
 │
 ├─ Sinks:
 │      62. HDMI / DisplayPort 2 Output [vol: 1.00]
 │  *   74. Speaker      [vol: 0.83 MUTED]
 │
 ├─ Sources:
 │  *   72. Digital Microphone [vol: 0.40]
 │
 └─ Streams:
        94. Firefox

Video
 ├─ Sinks:
 │      12. Non audio
''');
    expect(audio.outputs.map((d) => d.id), [62, 74]);
    expect(audio.outputs.last.isDefault, isTrue);
    expect(audio.outputs.last.muted, isTrue);
    expect(audio.outputs.last.volume, 0.83);
    expect(audio.inputs.single.name, 'Digital Microphone');
    expect(audio.defaultInput?.volume, 0.4);
  });

  test('timedatectl and localectl', () {
    final clock = HostSystemTools.parseTimedatectl(
      'Timezone=Europe/Rome\nNTP=yes\nCanNTP=yes\nNTPSynchronized=no\n',
    );
    expect(clock.timezone, 'Europe/Rome');
    expect(clock.ntp, isTrue);
    expect(clock.synchronized, isFalse);
    final locale = HostSystemTools.parseLocalectl(
      '   System Locale: LANG=en_US.UTF-8\n'
      '                  LC_TIME=it_IT.UTF-8\n'
      '       VC Keymap: us\n',
    );
    expect(locale.language, 'en_US.UTF-8');
    expect(locale.formats, 'it_IT.UTF-8');
  });

  test('BlueZ objects: devices with their battery', () {
    final peers = HostSystemTools.parseBluezObjects({
      '/org/bluez/hci0': {'org.bluez.Adapter1': <String, Object?>{}},
      '/org/bluez/hci0/dev_11': {
        'org.bluez.Device1': {
          'Address': '11:22',
          'Alias': 'Headphones',
          'Icon': 'audio-headphones',
          'Paired': true,
          'Connected': true,
        },
        'org.bluez.Battery1': {'Percentage': 80},
      },
      '/org/bluez/hci0/dev_33': {
        'org.bluez.Device1': {'Address': '33:44', 'Paired': false},
      },
    });
    expect(peers.map((p) => p.name), ['33:44', 'Headphones']);
    expect(peers.last.battery, 80);
    expect(peers.last.paired, isTrue);
  });

  test('accounts: people with a login shell, administrators from wheel', () {
    final users = HostSystemTools.parseUsers(
      'root:x:0:0:root:/root:/bin/bash\n'
          'ada:x:1000:1000:Ada Lovelace,,,:/home/ada:/bin/bash\n'
          'bob:x:1001:1001::/home/bob:/bin/zsh\n'
          'svc:x:1002:1002::/:/sbin/nologin\n',
      'wheel:x:10:ada\n',
    );
    expect(users.map((u) => u.login), ['ada', 'bob']);
    expect(users.first.name, 'Ada Lovelace');
    expect(users.first.admin, isTrue);
    expect(users.last.name, 'bob');
    expect(users.last.admin, isFalse);
  });

  test('the notification history gives one app per desktop entry', () {
    final apps = HostSystemTools.parseHistory([
      [1, 'Files', '', 'a', 'b', <String>[], 1, '', 'org.gnome.Nautilus'],
      [2, 'Firefox', '', 'a', 'b', <String>[], 1, '', ''],
      [3, 'Files', '', 'c', 'd', <String>[], 1, '', 'org.gnome.Nautilus'],
    ]);
    expect(apps.map((a) => a.key), ['org.gnome.Nautilus', 'Firefox']);
  });

  test('pci.ids names the graphics adapter', () {
    const ids =
        '8086  Intel Corporation\n'
        '\t46a6  Alder Lake-P GT2 [Iris Xe Graphics]\n'
        '1af4  Red Hat, Inc.\n'
        '\t1050  Virtio 1.0 GPU\n';
    expect(
      HostReader.pciName(ids, '0x8086', '0x46a6'),
      'Intel Alder Lake-P GT2 [Iris Xe Graphics]',
    );
    expect(
      HostReader.pciName(ids, '0x1af4', '0x1050'),
      'Red Hat Virtio 1.0 GPU',
    );
    expect(HostReader.pciName(ids, '0x10de', '0x1234'), '10de:1234');
  });

  test('host names from computer names', () {
    expect(HostSystemTools.hostnameFor('Ada’s Silica'), 'ada-s-silica');
    expect(HostSystemTools.hostnameFor('***'), 'silica');
  });

  test('errors: polkit, refusals, missing tools', () {
    expect(
      errorOf(
        const CommandResult(
          1,
          '',
          'Failed to set time zone: Interactive authentication required.',
        ),
      ).kind,
      ToolErrorKind.authentication,
    );
    expect(
      errorOf(
        const CommandResult(
          4,
          '',
          'Error: Connection activation failed: Secrets were required.',
        ),
      ).kind,
      ToolErrorKind.refused,
    );
    expect(errorOf(const CommandResult.missing()).kind, ToolErrorKind.missing);
    final l = AppLocalizationsEn();
    expect(
      errorText(l, const ToolError(ToolErrorKind.authentication)),
      contains('administrator'),
    );
    expect(
      errorText(
        l,
        const ToolError(ToolErrorKind.failed, 'nmcli: Error: no device'),
      ),
      contains('Error: no device'),
    );
  });

  test('the real tools run the expected commands', () async {
    final runs = <String>[];
    final tools = HostSystemTools(
      run: (exe, args) async {
        runs.add('$exe ${args.join(' ')}');
        return const CommandResult(0, '', '');
      },
      env: const {},
    );
    await tools.joinWifi('Cafe', password: 'secret');
    await tools.forgetConnection('Office');
    await tools.setAutoconnect('Home', false);
    await tools.setDefaultAudio(51);
    await tools.setAudioVolume(52, 0.5);
    await tools.setTimezone('Europe/Rome');
    await tools.setNtp(true);
    await tools.setLocale(language: 'it_IT.UTF-8', formats: 'en_GB.UTF-8');
    await tools.setComputerName('Ada’s Silica');
    await tools.setDefaultBrowser('firefox.desktop');
    expect(runs, [
      'nmcli device wifi connect Cafe password secret',
      'nmcli connection delete id Office',
      'nmcli connection modify id Home connection.autoconnect no',
      'wpctl set-default 51',
      'wpctl set-volume 52 0.50',
      'timedatectl set-timezone Europe/Rome',
      'timedatectl set-ntp true',
      'localectl set-locale LANG=it_IT.UTF-8 LC_TIME=en_GB.UTF-8 '
          'LC_NUMERIC=en_GB.UTF-8 LC_MONETARY=en_GB.UTF-8 '
          'LC_MEASUREMENT=en_GB.UTF-8 LC_PAPER=en_GB.UTF-8',
      'hostnamectl set-hostname --pretty Ada’s Silica',
      'hostnamectl set-hostname --static ada-s-silica',
      'xdg-settings set default-web-browser firefox.desktop',
    ]);
  });

  test('xkb rules: layout and variant names', () {
    final names = HostSystemTools.parseKeymapNames(
      '! model\n  pc105   Generic 105-key PC\n\n'
      '! layout\n  us   English (US)\n  it   Italian\n\n'
      '! variant\n  nodeadkeys   de: German (no dead keys)\n'
      '  winkeys   it: Italian (Winkeys)\n\n! option\n  caps   Caps Lock\n',
    );
    expect(names['it'], 'Italian');
    expect(names['de(nodeadkeys)'], 'German (no dead keys)');
    expect(names['it(winkeys)'], 'Italian (Winkeys)');
    expect(names.containsKey('pc105'), isFalse);
    expect(names.containsKey('caps'), isFalse);
  });

  test(
    'keymap lists come from localectl; a layout is never passed raw',
    () async {
      final runs = <String>[];
      final tools = HostSystemTools(
        run: (exe, args) async {
          runs.add('$exe ${args.join(' ')}');
          return const CommandResult(0, 'us\nit\n', '');
        },
      );
      expect(await tools.keymapLayouts(), ['us', 'it']);
      expect(await tools.keymapVariants('de'), ['us', 'it']);
      expect(await tools.keymapVariants('--help; rm'), isEmpty);
      expect(runs, [
        'localectl list-x11-keymap-layouts',
        'localectl list-x11-keymap-variants de',
      ]);
    },
  );
}
