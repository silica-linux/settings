// Wi-Fi, Bluetooth, Network and VPN (ST-NET-01..03). Wi-Fi on/off goes through silica-daemon;
// the networks around, joining one (with its password), the details, auto-join and forgetting
// a network go through NetworkManager (nmcli). Bluetooth on/off goes through the daemon;
// scanning, pairing, connecting and forgetting devices through BlueZ. The Network pane lists
// NetworkManager's devices with their addresses; VPN lists, connects and disconnects the VPN
// and WireGuard connections. Asking to join networks (#65), devices that need a PIN (#66), the
// firewall and importing VPN configurations (#67) wait for their backends.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/tools.dart';
import '../ui/errors.dart';
import '../ui/grouped.dart';
import '../ui/popup.dart';
import '../ui/symbol.dart';

/// The Wi-Fi symbol for a signal strength (0–100).
String wifiSymbol(int strength) => switch (strength) {
  < 25 => 'wifi-0',
  < 50 => 'wifi-1',
  < 75 => 'wifi-2',
  _ => 'wifi',
};

/// A coloured status dot and its text (Connected in green, otherwise red or gray).
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color gray = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 6),
      Text(text, style: settingsText(13, SettingsColors.of(context).secondary)),
    ],
  );
}

/// The card at the top of Wi-Fi and Bluetooth: the icon, the name, a description and the
/// switch; [below] goes in the same group under a separator.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.pane,
    required this.title,
    required this.description,
    required this.switchKey,
    required this.value,
    required this.onChanged,
    this.below,
  });

  final PaneId pane;
  final String title;
  final String description;
  final Key switchKey;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? below;

  @override
  Widget build(BuildContext context) => GroupBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(symbol: pane.symbol, tint: pane.tint, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: RowTitles(title: title, subtitle: description),
              ),
              const SizedBox(width: 12),
              SilicaSwitch(
                key: switchKey,
                value: value,
                size: ControlSize.small,
                semanticLabel: title,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (below case final below?) ...[const RowSeparator(), below],
      ],
    ),
  );
}

/// The signal of a network: a lock when it is secured, then the strength.
class _Signal extends StatelessWidget {
  const _Signal({required this.secured, required this.strength});
  final bool secured;
  final int? strength;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (secured) SettingsSymbol('lock-fill', color: colors.text, size: 12),
        const SizedBox(width: 8),
        if (strength case final strength?)
          SettingsSymbol(wifiSymbol(strength), color: colors.text, size: 16)
        else
          const SizedBox(width: 16),
      ],
    );
  }
}

class WifiPane extends StatefulWidget {
  const WifiPane({super.key});

  @override
  State<WifiPane> createState() => _WifiPaneState();
}

class _WifiPaneState extends State<WifiPane> {
  List<AccessPoint> _points = const [];
  List<SavedConnection> _saved = const [];
  bool _scanning = false;
  String? _error;
  String _lastSsid = '';
  bool _lastEnabled = false;
  Timer? _refresh;

  SystemTools get _tools => ServicesScope.of(context).tools;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refresh == null) {
      _load(rescan: true);
      // The networks around change: look again every 10 s while the pane is open.
      _refresh = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool rescan = false}) async {
    if (rescan) setState(() => _scanning = true);
    final tools = _tools;
    final points = await tools.accessPoints(rescan: rescan);
    final saved = await tools.savedConnections();
    if (!mounted) return;
    setState(() {
      _points = points;
      _saved = saved;
      _scanning = false;
    });
  }

  Future<void> _run(Future<ToolError?> change) async {
    final error = await change;
    if (!mounted) return;
    setState(
      () => _error = error == null
          ? null
          : errorText(AppLocalizations.of(context), error),
    );
    await _load();
  }

  bool _isSaved(String ssid) => _saved.any((c) => c.isWifi && c.name == ssid);

  SavedConnection? _savedNamed(String ssid) =>
      _saved.where((c) => c.isWifi && c.name == ssid).firstOrNull;

  Future<void> _join(AccessPoint ap) async {
    if (_isSaved(ap.ssid) || !ap.secured) {
      await _run(_tools.joinWifi(ap.ssid));
      return;
    }
    await showJoinSheet(context, ssid: ap.ssid, tools: _tools);
    if (mounted) await _load();
  }

  List<MenuEntry> _networkMenu(AppLocalizations l, AccessPoint ap) {
    final saved = _savedNamed(ap.ssid);
    return [
      if (ap.inUse)
        MenuAction(
          l.wifiDisconnect,
          onSelected: () async {
            final devices = await _tools.networkDevices();
            final wifi = devices.where((d) => d.type == 'wifi').firstOrNull;
            if (wifi != null) await _run(_tools.disconnect(wifi.name));
          },
        )
      else
        MenuAction(l.wifiConnect, onSelected: () => _join(ap)),
      if (saved != null) ...[
        const MenuDivider(),
        MenuAction(
          l.wifiAutoJoin,
          checked: saved.autoconnect,
          onSelected: () =>
              _run(_tools.setAutoconnect(saved.name, !saved.autoconnect)),
        ),
        MenuAction(
          l.wifiForget,
          onSelected: () => _run(_tools.forgetConnection(saved.name)),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final system = ServicesScope.of(context).system;
    return SystemStateBuilder(
      builder: (context, state) {
        if (state.wifiSsid != _lastSsid || state.wifiEnabled != _lastEnabled) {
          _lastSsid = state.wifiSsid;
          _lastEnabled = state.wifiEnabled;
          // Read the list again when the connection changes.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load();
          });
        }
        final on = state.wifiAvailable && state.wifiEnabled;
        final current = _points.where((p) => p.inUse).firstOrNull;
        final known = _points
            .where((p) => !p.inUse && _isSaved(p.ssid))
            .toList();
        final other = _points
            .where((p) => !p.inUse && !_isSaved(p.ssid))
            .toList();
        return PanePage(
          children: [
            _SwitchCard(
              pane: PaneId.wifi,
              title: l.paneWifi,
              description: state.wifiAvailable
                  ? l.wifiDescription
                  : l.wifiNoDevice,
              switchKey: const ValueKey('wifi switch'),
              value: state.wifiEnabled,
              onChanged: state.wifiAvailable
                  ? (on) => system.setWifiEnabled(on)
                  : null,
              below: on && current != null
                  ? Padding(
                      key: ValueKey('current ${current.ssid}'),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RowTitles(title: current.ssid),
                                const SizedBox(height: 2),
                                StatusLine(
                                  text: l.wifiConnected,
                                  color: StatusLine.green,
                                ),
                              ],
                            ),
                          ),
                          _Signal(
                            secured: current.secured,
                            strength: current.strength,
                          ),
                          const SizedBox(width: 10),
                          SilicaButton(
                            key: const ValueKey('wifi details'),
                            label: l.detailsButton,
                            size: ControlSize.small,
                            onPressed: () async {
                              await showWifiDetails(
                                context,
                                ssid: current.ssid,
                                tools: _tools,
                              );
                              if (mounted) await _load();
                            },
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            if (_error case final error?) ErrorLine(error),
            if (on && known.isNotEmpty)
              SettingsGroup(
                heading: l.wifiKnownNetworks,
                children: [
                  for (final ap in known)
                    _NetworkRow(
                      key: ValueKey('known ${ap.ssid}'),
                      ap: ap,
                      onTap: () => _join(ap),
                      menu: () => _networkMenu(l, ap),
                    ),
                ],
              ),
            if (on)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: SectionHeading(l.wifiOtherNetworks)),
                      if (_scanning)
                        const Padding(
                          padding: EdgeInsets.only(right: 10, top: 12),
                          child: SilicaSpinner(size: 14),
                        ),
                    ],
                  ),
                  GroupBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (other.isEmpty)
                          ValueRow(
                            title: _scanning
                                ? l.wifiSearching
                                : l.wifiNoOtherNetworks,
                          ),
                        for (final (i, ap) in other.indexed) ...[
                          if (i > 0) const RowSeparator(),
                          _NetworkRow(
                            key: ValueKey('other ${ap.ssid}'),
                            ap: ap,
                            onTap: () => _join(ap),
                            menu: () => _networkMenu(l, ap),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: SettingsMetrics.groupSpacing),
                  ButtonBar(
                    buttons: [
                      SilicaButton(
                        key: const ValueKey('wifi other'),
                        label: l.wifiOther,
                        size: ControlSize.small,
                        onPressed: () async {
                          await showJoinSheet(
                            context,
                            ssid: null,
                            tools: _tools,
                          );
                          if (mounted) await _load();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            SettingsGroup(
              unavailable: true,
              issue: Issues.wifiAskToJoin,
              children: [
                PopUpRow<int>(
                  title: l.wifiAskToJoin,
                  subtitle: l.wifiAskToJoinHelp,
                  items: [PopUpItem(0, l.wifiAskNotify)],
                  value: 0,
                  onChanged: (_) {},
                ),
                PopUpRow<int>(
                  title: l.wifiAskToJoinHotspots,
                  subtitle: l.wifiAskToJoinHotspotsHelp,
                  items: [PopUpItem(0, l.wifiAskAsk)],
                  value: 0,
                  onChanged: (_) {},
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A network: its name, the lock and the signal, and the "…" menu; a click joins it.
class _NetworkRow extends StatelessWidget {
  const _NetworkRow({
    super.key,
    required this.ap,
    required this.onTap,
    required this.menu,
  });

  final AccessPoint ap;
  final VoidCallback onTap;
  final List<MenuEntry> Function() menu;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(
          left: SettingsMetrics.rowTextInset,
          right: SettingsMetrics.trailingInset + 2,
        ),
        child: Row(
          children: [
            Expanded(child: RowTitles(title: ap.ssid)),
            _Signal(secured: ap.secured, strength: ap.strength),
            const SizedBox(width: 10),
            MoreButton(
              entries: menu,
              semanticLabel: AppLocalizations.of(context).moreFor(ap.ssid),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Asks for a network's password (or, with no [ssid], a hidden network's name too) and joins.
Future<void> showJoinSheet(
  BuildContext context, {
  required String? ssid,
  required SystemTools tools,
}) {
  final l = AppLocalizations.of(context);
  return showWindowSheet<void>(
    context,
    semanticLabel: ssid == null ? l.wifiOther : l.wifiJoinTitle(ssid),
    builder: (context, sheet) =>
        _JoinSheet(ssid: ssid, tools: tools, close: sheet.close),
  );
}

class _JoinSheet extends StatefulWidget {
  const _JoinSheet({
    required this.ssid,
    required this.tools,
    required this.close,
  });
  final String? ssid;
  final SystemTools tools;
  final VoidCallback close;

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _ssid => widget.ssid ?? _name.text.trim();

  Future<void> _join() async {
    if (_ssid.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final l = AppLocalizations.of(context);
    final error = await widget.tools.joinWifi(_ssid, password: _password.text);
    if (!mounted) return;
    if (error == null) {
      widget.close();
      return;
    }
    setState(() {
      _busy = false;
      _error = error.kind == ToolErrorKind.refused
          ? l.wifiWrongPassword
          : errorText(l, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    Widget field(String label, Widget input) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: settingsText(13, colors.text),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: input),
        ],
      ),
    );
    return SizedBox(
      width: 420,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.ssid == null
                  ? l.wifiJoinHidden
                  : l.wifiJoinTitle(widget.ssid!),
              style: settingsText(13, colors.text, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l.wifiJoinHelp,
              style: settingsText(11, colors.secondary, height: 1.3),
            ),
            if (widget.ssid == null)
              field(
                l.wifiNetworkName,
                SilicaTextField(
                  key: const ValueKey('join name'),
                  controller: _name,
                  autofocus: true,
                  semanticLabel: l.wifiNetworkName,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            field(
              l.wifiPassword,
              SilicaTextField(
                key: const ValueKey('join password'),
                controller: _password,
                secure: true,
                autofocus: widget.ssid != null,
                semanticLabel: l.wifiPassword,
                onSubmitted: (_) => _join(),
              ),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error,
                  key: const ValueKey('join error'),
                  style: settingsText(11, const Color(0xFFE0393E)),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (_busy) const SilicaSpinner(size: 16),
                const Spacer(),
                SilicaButton(label: l.cancel, onPressed: widget.close),
                const SizedBox(width: 8),
                SilicaButton(
                  key: const ValueKey('join'),
                  label: l.wifiJoin,
                  role: ButtonRole.primary,
                  onPressed: _busy || _ssid.isEmpty ? null : _join,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The current network's details: auto-join, the addresses, forgetting it.
Future<void> showWifiDetails(
  BuildContext context, {
  required String ssid,
  required SystemTools tools,
}) => showWindowSheet<void>(
  context,
  semanticLabel: ssid,
  builder: (context, sheet) =>
      _WifiDetails(ssid: ssid, tools: tools, close: sheet.close),
);

class _WifiDetails extends StatefulWidget {
  const _WifiDetails({
    required this.ssid,
    required this.tools,
    required this.close,
  });
  final String ssid;
  final SystemTools tools;
  final VoidCallback close;

  @override
  State<_WifiDetails> createState() => _WifiDetailsState();
}

class _WifiDetailsState extends State<_WifiDetails> {
  DeviceDetails _details = const DeviceDetails();
  SavedConnection? _saved;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devices = await widget.tools.networkDevices();
    final wifi = devices.where((d) => d.type == 'wifi').firstOrNull;
    final details = wifi == null
        ? const DeviceDetails()
        : await widget.tools.deviceDetails(wifi.name);
    final saved = (await widget.tools.savedConnections())
        .where((c) => c.isWifi && c.name == widget.ssid)
        .firstOrNull;
    if (!mounted) return;
    setState(() {
      _details = details;
      _saved = saved;
    });
  }

  Future<void> _change(Future<ToolError?> change, {bool close = false}) async {
    final error = await change;
    if (!mounted) return;
    if (error == null && close) {
      widget.close();
      return;
    }
    setState(
      () => _error = error == null
          ? null
          : errorText(AppLocalizations.of(context), error),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final saved = _saved;
    String or(String s) => s.isEmpty ? '—' : s;
    return SizedBox(
      width: 528,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(
                  symbol: PaneId.wifi.symbol,
                  tint: PaneId.wifi.tint,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ssid,
                        style: settingsText(
                          13,
                          colors.text,
                          weight: FontWeight.w600,
                        ),
                      ),
                      StatusLine(
                        text: l.wifiConnected,
                        color: StatusLine.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GroupBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchRow(
                    key: const ValueKey('auto join'),
                    title: l.wifiAutoJoinTitle,
                    value: saved?.autoconnect ?? false,
                    onChanged: saved == null
                        ? null
                        : (v) => _change(
                            widget.tools.setAutoconnect(saved.name, v),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GroupBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueRow(
                    title: l.networkIpAddress,
                    trailing: RowValue(or(_details.ipv4.join(', '))),
                  ),
                  const RowSeparator(),
                  ValueRow(
                    title: l.networkRouter,
                    trailing: RowValue(or(_details.gateway)),
                  ),
                  const RowSeparator(),
                  ValueRow(
                    title: l.networkDns,
                    trailing: RowValue(or(_details.dns.join(', '))),
                  ),
                  const RowSeparator(),
                  ValueRow(
                    title: l.networkHardwareAddress,
                    trailing: RowValue(or(_details.hardwareAddress)),
                  ),
                ],
              ),
            ),
            if (_error case final error?) ErrorLine(error),
            const SizedBox(height: 16),
            Row(
              children: [
                SilicaButton(
                  key: const ValueKey('forget network'),
                  label: l.wifiForget,
                  onPressed: saved == null
                      ? null
                      : () => _change(
                          widget.tools.forgetConnection(saved.name),
                          close: true,
                        ),
                ),
                const Spacer(),
                SilicaButton(
                  key: const ValueKey('details ok'),
                  label: l.ok,
                  role: ButtonRole.primary,
                  onPressed: widget.close,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The symbol for a BlueZ device icon.
String bluetoothSymbol(String icon) => switch (icon) {
  final i
      when i.startsWith('audio-headphones') || i.startsWith('audio-headset') =>
    'headphones',
  final i when i.startsWith('audio') => 'speaker',
  final i when i.startsWith('input-mouse') => 'mouse',
  final i when i.startsWith('input-keyboard') => 'keyboard',
  final i when i.startsWith('input-gaming') => 'gamecontroller',
  final i when i.startsWith('phone') => 'smartphone',
  final i when i.startsWith('computer') => 'laptop',
  _ => 'bluetooth',
};

class BluetoothPane extends StatefulWidget {
  const BluetoothPane({super.key});

  @override
  State<BluetoothPane> createState() => _BluetoothPaneState();
}

class _BluetoothPaneState extends State<BluetoothPane> {
  List<BluetoothPeer> _peers = const [];
  bool _discovering = false;
  String? _error;
  Timer? _poll;
  SystemTools? _tools;
  final Set<String> _busy = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tools ??= ServicesScope.of(context).tools;
    if (_poll == null) {
      _load();
      // Devices appear while the adapter scans: read them again every 2 s.
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _load());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_discovering) _tools?.setBluetoothDiscovery(false);
    super.dispose();
  }

  Future<void> _load() async {
    final peers = await _tools!.bluetoothPeers();
    if (mounted) setState(() => _peers = peers);
  }

  Future<void> _discover(bool powered) async {
    if (powered == _discovering) return;
    _discovering = powered;
    final error = await _tools!.setBluetoothDiscovery(powered);
    if (error != null && error.kind != ToolErrorKind.missing) {
      _discovering = false;
    }
  }

  Future<void> _run(String path, Future<ToolError?> change) async {
    setState(() => _busy.add(path));
    final error = await change;
    if (!mounted) return;
    setState(() {
      _busy.remove(path);
      _error = error == null
          ? null
          : '${errorText(AppLocalizations.of(context), error)} '
                '${AppLocalizations.of(context).bluetoothPinNote(Issues.bluetoothAgent)}';
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final system = ServicesScope.of(context).system;
    final tools = _tools!;
    return SystemStateBuilder(
      builder: (context, state) {
        final on = state.bluetoothAvailable && state.bluetoothPowered;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _discover(on);
        });
        final paired = _peers.where((p) => p.paired).toList();
        final nearby = _peers.where((p) => !p.paired).toList();
        Widget icon(BluetoothPeer p) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.dark
                ? const Color(0xFF48484A)
                : const Color(0xFFE3E3E5),
          ),
          alignment: Alignment.center,
          child: SettingsSymbol(
            bluetoothSymbol(p.icon),
            color: colors.text,
            size: 14,
          ),
        );
        return PanePage(
          children: [
            _SwitchCard(
              pane: PaneId.bluetooth,
              title: l.paneBluetooth,
              description: state.bluetoothAvailable
                  ? l.bluetoothDescription
                  : l.bluetoothNoAdapter,
              switchKey: const ValueKey('bluetooth switch'),
              value: state.bluetoothPowered,
              onChanged: state.bluetoothAvailable
                  ? (on) => system.setBluetoothPowered(on)
                  : null,
            ),
            if (_error case final error?) ErrorLine(error),
            if (on)
              SettingsGroup(
                heading: l.bluetoothMyDevices,
                children: [
                  if (paired.isEmpty) ValueRow(title: l.bluetoothNoDevices),
                  for (final p in paired)
                    ValueRow(
                      key: ValueKey('device ${p.address}'),
                      title: p.name,
                      subtitle: [
                        p.connected
                            ? l.bluetoothConnected
                            : l.bluetoothNotConnected,
                        if (p.battery case final b?) '$b %',
                      ].join(' · '),
                      leading: icon(p),
                      height: 44,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_busy.contains(p.path))
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SilicaSpinner(size: 14),
                            ),
                          SilicaButton(
                            label: p.connected
                                ? l.bluetoothDisconnect
                                : l.bluetoothConnect,
                            size: ControlSize.small,
                            onPressed: _busy.contains(p.path)
                                ? null
                                : () => _run(
                                    p.path,
                                    tools.connectBluetooth(
                                      p.path,
                                      !p.connected,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          MoreButton(
                            semanticLabel: l.moreFor(p.name),
                            entries: () => [
                              MenuAction(
                                l.bluetoothForget,
                                onSelected: () =>
                                    _run(p.path, tools.forgetBluetooth(p.path)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (on)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: SectionHeading(l.bluetoothNearby)),
                      const Padding(
                        padding: EdgeInsets.only(right: 10, top: 12),
                        child: SilicaSpinner(size: 14),
                      ),
                    ],
                  ),
                  GroupBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (nearby.isEmpty)
                          ValueRow(title: l.bluetoothNearbyNone),
                        for (final (i, p) in nearby.indexed) ...[
                          if (i > 0) const RowSeparator(),
                          ValueRow(
                            key: ValueKey('nearby ${p.address}'),
                            title: p.name,
                            leading: icon(p),
                            height: 44,
                            trailing: _busy.contains(p.path)
                                ? const SilicaSpinner(size: 14)
                                : SilicaButton(
                                    label: l.bluetoothConnect,
                                    size: ControlSize.small,
                                    onPressed: () => _run(
                                      p.path,
                                      tools.pairBluetooth(p.path),
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    child: Text(
                      l.bluetoothPinNote(Issues.bluetoothAgent),
                      style: settingsText(11, colors.secondary, height: 1.3),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// The name of a NetworkManager device type.
String deviceTypeName(AppLocalizations l, NetworkDevice d) => switch (d.type) {
  'wifi' => l.paneWifi,
  'ethernet' => l.networkWired,
  'bridge' => l.networkBridge,
  'bt' => l.paneBluetooth,
  'gsm' || 'modem' => l.networkCellular,
  'wireguard' || 'vpn' || 'tun' => l.paneVpn,
  _ => d.type,
};

String deviceSymbol(NetworkDevice d) => switch (d.type) {
  'wifi' => 'wifi',
  'ethernet' => 'ethernet',
  'bt' => 'bluetooth',
  'gsm' || 'modem' => 'signal',
  'wireguard' || 'vpn' || 'tun' => 'network',
  _ => 'link',
};

class NetworkPane extends StatefulWidget {
  const NetworkPane({super.key});

  @override
  State<NetworkPane> createState() => _NetworkPaneState();
}

class _NetworkPaneState extends State<NetworkPane> {
  List<NetworkDevice> _devices = const [];
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final devices = await ServicesScope.of(context).tools.networkDevices();
    if (!mounted) return;
    setState(
      () => _devices = [
        for (final d in devices)
          if (const {
            'wifi',
            'ethernet',
            'bridge',
            'bt',
            'gsm',
            'modem',
          }.contains(d.type))
            d,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tools = ServicesScope.of(context).tools;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            if (_devices.isEmpty) ValueRow(title: l.networkNoServices),
            for (final d in _devices)
              _ServiceRow(
                key: ValueKey('service ${d.name}'),
                device: d,
                title: deviceTypeName(l, d),
                onTap: () async {
                  await showServiceDetails(context, device: d, tools: tools);
                  if (mounted) await _load();
                },
              ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
        SettingsGroup(
          unavailable: true,
          issue: Issues.networkExtras,
          children: [SwitchRow(title: l.networkFirewall, value: false)],
        ),
      ],
    );
  }
}

/// A service row of the Network pane (INV-D: 52 pt, a 32 pt tile, the name and a status line
/// with a 9 pt dot, green connected, red not connected).
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    super.key,
    required this.device,
    required this.title,
    required this.onTap,
  });

  final NetworkDevice device;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final connected = device.connected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 12),
          child: Row(
            children: [
              IconTile(
                symbol: deviceSymbol(device),
                tint: PaneId.network.tint,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RowTitles(title: title),
                    StatusLine(
                      text: connected
                          ? l.networkConnected
                          : device.state == 'unavailable'
                          ? l.networkUnplugged
                          : l.networkNotConnected,
                      color: connected ? StatusLine.green : StatusLine.red,
                    ),
                  ],
                ),
              ),
              const RowChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A network service's addresses, with Connect or Disconnect.
Future<void> showServiceDetails(
  BuildContext context, {
  required NetworkDevice device,
  required SystemTools tools,
}) => showWindowSheet<void>(
  context,
  semanticLabel: device.name,
  builder: (context, sheet) =>
      _ServiceDetails(device: device, tools: tools, close: sheet.close),
);

class _ServiceDetails extends StatefulWidget {
  const _ServiceDetails({
    required this.device,
    required this.tools,
    required this.close,
  });
  final NetworkDevice device;
  final SystemTools tools;
  final VoidCallback close;

  @override
  State<_ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<_ServiceDetails> {
  DeviceDetails _details = const DeviceDetails();
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.tools.deviceDetails(widget.device.name).then((d) {
      if (mounted) setState(() => _details = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final d = widget.device;
    String or(String s) => s.isEmpty ? '—' : s;
    final rows = [
      (l.networkInterface, d.name),
      (l.networkIpAddress, _details.ipv4.join(', ')),
      (l.networkRouter, _details.gateway),
      (l.networkDns, _details.dns.join(', ')),
      (l.networkIpv6, _details.ipv6.join(', ')),
      (l.networkHardwareAddress, _details.hardwareAddress),
    ];
    return SizedBox(
      width: 528,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(
                  symbol: deviceSymbol(d),
                  tint: PaneId.network.tint,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceTypeName(l, d),
                        style: settingsText(
                          13,
                          colors.text,
                          weight: FontWeight.w600,
                        ),
                      ),
                      StatusLine(
                        text: d.connected
                            ? l.networkConnected
                            : l.networkNotConnected,
                        color: d.connected ? StatusLine.green : StatusLine.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GroupBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (title, value)) in rows.indexed) ...[
                    if (i > 0) const RowSeparator(),
                    ValueRow(title: title, trailing: RowValue(or(value))),
                  ],
                ],
              ),
            ),
            if (_error case final error?) ErrorLine(error),
            const SizedBox(height: 16),
            Row(
              children: [
                if (d.connected)
                  SilicaButton(
                    key: const ValueKey('service disconnect'),
                    label: l.networkDisconnect,
                    onPressed: () async {
                      final error = await widget.tools.disconnect(d.name);
                      if (!context.mounted) return;
                      if (error == null) {
                        widget.close();
                      } else {
                        setState(() => _error = errorText(l, error));
                      }
                    },
                  ),
                const Spacer(),
                SilicaButton(
                  label: l.ok,
                  role: ButtonRole.primary,
                  onPressed: widget.close,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VpnPane extends StatefulWidget {
  const VpnPane({super.key});

  @override
  State<VpnPane> createState() => _VpnPaneState();
}

class _VpnPaneState extends State<VpnPane> {
  List<SavedConnection> _vpns = const [];
  bool _loaded = false;
  String? _error;
  final Set<String> _busy = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final all = await ServicesScope.of(context).tools.savedConnections();
    if (mounted) setState(() => _vpns = all.where((c) => c.isVpn).toList());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tools = ServicesScope.of(context).tools;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            if (_vpns.isEmpty) EmptyState(l.vpnNone),
            for (final v in _vpns)
              ValueRow(
                key: ValueKey('vpn ${v.name}'),
                title: v.name,
                height: 44,
                subtitle: v.type == 'wireguard' ? 'WireGuard' : l.paneVpn,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusLine(
                      text: v.active
                          ? l.networkConnected
                          : l.networkNotConnected,
                      color: v.active ? StatusLine.green : StatusLine.gray,
                    ),
                    const SizedBox(width: 12),
                    SilicaSwitch(
                      value: v.active,
                      size: ControlSize.mini,
                      semanticLabel: v.name,
                      onChanged: _busy.contains(v.name)
                          ? null
                          : (on) async {
                              setState(() => _busy.add(v.name));
                              final error = await tools.setConnectionActive(
                                v.name,
                                on,
                              );
                              if (!mounted) return;
                              setState(() {
                                _busy.remove(v.name);
                                _error = error == null
                                    ? null
                                    : errorText(l, error);
                              });
                              await _load();
                            },
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (_error case final error?) ErrorLine(error),
        SettingsGroup(
          unavailable: true,
          issue: Issues.networkExtras,
          children: [ButtonRow(title: l.vpnAdd, label: l.addButton)],
        ),
      ],
    );
  }
}
