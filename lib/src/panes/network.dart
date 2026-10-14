// Wi-Fi, Bluetooth, Network and VPN (ST-NET-01..03), on silica-daemon: Wi-Fi on/off, the
// networks around and joining a saved one; Bluetooth on/off and connecting paired devices;
// the state of the services. Joining a new network (it needs a password), discovering
// Bluetooth devices, the firewall and VPNs have no backend yet and say so.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/system.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

/// The Wi-Fi symbol for a signal strength (0–100).
String wifiSymbol(int strength) => switch (strength) {
  < 25 => 'wifi-0',
  < 50 => 'wifi-1',
  < 75 => 'wifi-2',
  _ => 'wifi',
};

class WifiPane extends StatelessWidget {
  const WifiPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final system = ServicesScope.of(context).system;
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            children: [
              ValueRow(
                title: l.paneWifi,
                subtitle: state.wifiAvailable ? null : l.wifiNoDevice,
                leading: IconTile(
                  symbol: PaneId.wifi.symbol,
                  tint: PaneId.wifi.tint,
                  size: 32,
                ),
                trailing: SilicaSwitch(
                  key: const ValueKey('wifi switch'),
                  value: state.wifiEnabled,
                  size: ControlSize.mini,
                  semanticLabel: l.paneWifi,
                  onChanged: state.wifiAvailable
                      ? (on) => system.setWifiEnabled(on)
                      : null,
                ),
              ),
            ],
          ),
          if (state.wifiAvailable && state.wifiEnabled)
            _Networks(
              // Read the list again when the connection changes.
              key: ValueKey('${state.wifiSsid}/${state.wifiEnabled}'),
              system: system,
            ),
          SettingsGroup(
            unavailable: true,
            children: [
              PopUpRow<int>(
                title: l.wifiAskToJoin,
                items: [PopUpItem(0, l.wifiAskNotify)],
                value: 0,
              ),
              PopUpRow<int>(
                title: l.wifiAskToJoinHotspots,
                items: [PopUpItem(0, l.wifiAskNever)],
                value: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Networks extends StatefulWidget {
  const _Networks({super.key, required this.system});
  final SystemBackend system;

  @override
  State<_Networks> createState() => _NetworksState();
}

class _NetworksState extends State<_Networks> {
  late Future<List<WifiNetwork>> _networks = widget.system.wifiNetworks();

  void _reload() {
    setState(() {
      _networks = widget.system.wifiNetworks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return FutureBuilder<List<WifiNetwork>>(
      future: _networks,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <WifiNetwork>[];
        final current = all.where((n) => n.inUse).toList();
        final known = all.where((n) => n.saved && !n.inUse).toList();
        final other = all.where((n) => !n.saved && !n.inUse).toList();
        Widget signal(WifiNetwork n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (n.secured)
              SettingsSymbol('lock', color: colors.secondary, size: 12),
            const SizedBox(width: 6),
            SettingsSymbol(
              wifiSymbol(n.strength),
              color: colors.text,
              size: 16,
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final n in current)
              SettingsGroup(
                children: [
                  ValueRow(
                    key: ValueKey('current ${n.ssid}'),
                    title: n.ssid,
                    subtitle: l.wifiConnected,
                    trailing: signal(n),
                  ),
                ],
              ),
            if (known.isNotEmpty) ...[
              const SizedBox(height: SettingsMetrics.groupSpacing),
              SettingsGroup(
                heading: l.wifiKnownNetworks,
                children: [
                  for (final n in known)
                    ValueRow(
                      key: ValueKey('known ${n.ssid}'),
                      title: n.ssid,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          signal(n),
                          const SizedBox(width: 10),
                          SilicaButton(
                            label: l.wifiConnect,
                            onPressed: () async {
                              await widget.system.connectWifi(n.ssid);
                              if (mounted) _reload();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: SettingsMetrics.groupSpacing),
            SettingsGroup(
              heading: l.wifiOtherNetworks,
              footer: other.isEmpty ? null : l.wifiNewNetworkUnavailable,
              children: [
                if (snapshot.connectionState != ConnectionState.done)
                  ValueRow(
                    title: l.wifiSearching,
                    trailing: const SilicaSpinner(size: 16),
                  )
                else if (other.isEmpty)
                  ValueRow(title: l.wifiNoOtherNetworks)
                else
                  for (final n in other)
                    ValueRow(
                      key: ValueKey('other ${n.ssid}'),
                      title: n.ssid,
                      trailing: signal(n),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class BluetoothPane extends StatelessWidget {
  const BluetoothPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final system = ServicesScope.of(context).system;
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            children: [
              ValueRow(
                title: l.paneBluetooth,
                subtitle: state.bluetoothAvailable
                    ? null
                    : l.bluetoothNoAdapter,
                leading: IconTile(
                  symbol: PaneId.bluetooth.symbol,
                  tint: PaneId.bluetooth.tint,
                  size: 32,
                ),
                trailing: SilicaSwitch(
                  key: const ValueKey('bluetooth switch'),
                  value: state.bluetoothPowered,
                  size: ControlSize.mini,
                  semanticLabel: l.paneBluetooth,
                  onChanged: state.bluetoothAvailable
                      ? (on) => system.setBluetoothPowered(on)
                      : null,
                ),
              ),
            ],
          ),
          if (state.bluetoothAvailable && state.bluetoothPowered)
            _Devices(system: system),
          SettingsGroup(
            heading: l.bluetoothNearby,
            unavailable: true,
            children: [ValueRow(title: l.bluetoothNearbyNone)],
          ),
        ],
      ),
    );
  }
}

class _Devices extends StatefulWidget {
  const _Devices({required this.system});
  final SystemBackend system;

  @override
  State<_Devices> createState() => _DevicesState();
}

class _DevicesState extends State<_Devices> {
  late Future<List<BluetoothDevice>> _devices = widget.system
      .bluetoothDevices();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<BluetoothDevice>>(
      future: _devices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <BluetoothDevice>[];
        return SettingsGroup(
          heading: l.bluetoothMyDevices,
          children: [
            if (devices.isEmpty)
              ValueRow(title: l.bluetoothNoDevices)
            else
              for (final d in devices)
                ValueRow(
                  key: ValueKey('device ${d.address}'),
                  title: d.name.isEmpty ? d.address : d.name,
                  subtitle: d.connected
                      ? l.bluetoothConnected
                      : l.bluetoothNotConnected,
                  trailing: SilicaButton(
                    label: d.connected
                        ? l.bluetoothDisconnect
                        : l.bluetoothConnect,
                    onPressed: () async {
                      await widget.system.connectBluetooth(
                        d.address,
                        connect: !d.connected,
                      );
                      if (mounted) {
                        setState(() {
                          _devices = widget.system.bluetoothDevices();
                        });
                      }
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// A service row of the Network pane (INV-D: 52 pt, a 32 pt tile, the name and a status line
/// with a 9 pt dot, green connected, red not connected).
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.title,
    required this.symbol,
    required this.connected,
    required this.status,
  });

  final String title;
  final String symbol;
  final bool connected;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SettingsMetrics.rowTextInset,
        ),
        child: Row(
          children: [
            IconTile(symbol: symbol, tint: PaneId.network.tint, size: 32),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: settingsText(13, colors.text)),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(status, style: settingsText(11, colors.secondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkPane extends StatelessWidget {
  const NetworkPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            children: [
              _ServiceRow(
                title: l.paneWifi,
                symbol: 'wifi',
                connected: state.wifiEnabled && state.wifiSsid.isNotEmpty,
                status: !state.wifiEnabled
                    ? l.networkOff
                    : state.wifiSsid.isEmpty
                    ? l.networkNotConnected
                    : l.networkConnected,
              ),
              _ServiceRow(
                title: l.networkWired,
                symbol: 'network',
                connected: state.wired,
                status: state.wired
                    ? l.networkConnected
                    : l.networkNotConnected,
              ),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            children: [SwitchRow(title: l.networkFirewall, value: false)],
          ),
        ],
      ),
    );
  }
}

class VpnPane extends StatelessWidget {
  const VpnPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(unavailable: true, children: [EmptyState(l.vpnNone)]),
        ButtonBar(buttons: [SilicaButton(label: l.vpnAdd, onPressed: null)]),
      ],
    );
  }
}
