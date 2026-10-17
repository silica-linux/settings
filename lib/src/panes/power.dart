// Energy (ST-PWR-01: three switches) and Battery (machines with a battery). Real: the level and
// the charge (UPower through silica-daemon), the time left and the battery's health (UPower), the
// power mode and Low Power Mode (power-profiles-daemon, when the system has it), and the idle
// policy in power.json: when the display turns off, when the computer sleeps and whether it may
// (Ossido counts the idle time; silica-daemon holds the inhibitor, #68), and Wake on LAN
// (NetworkManager). Starting again after a power failure and optimized charging need firmware
// or root services the image does not have.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../services.dart';
import '../system/settings_files.dart';
import '../style.dart';
import '../system/tools.dart';
import '../ui/errors.dart';
import '../ui/grouped.dart';

String profileLabel(AppLocalizations l, PowerProfile p) => switch (p) {
  PowerProfile.powerSaver => l.powerSaver,
  PowerProfile.balanced => l.powerBalanced,
  PowerProfile.performance => l.powerPerformance,
};

/// Reads the power state once and keeps the last error of a change.
mixin _PowerState<T extends StatefulWidget> on State<T> {
  PowerState? power;
  String? error;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      load();
    }
  }

  /// Wake on LAN of the saved Ethernet connections; null when there are none.
  bool? wakeOnLan;

  Future<void> load() async {
    final tools = ServicesScope.of(context).tools;
    final state = await tools.power();
    final wake = await tools.wakeOnLan();
    if (mounted) {
      setState(() {
        power = state;
        wakeOnLan = wake;
      });
    }
  }

  Future<void> setWakeOnLan(bool on) async {
    final result = await ServicesScope.of(context).tools.setWakeOnLan(on);
    if (!mounted) return;
    setState(
      () => error = result == null
          ? null
          : errorText(AppLocalizations.of(context), result),
    );
    await load();
  }

  Future<void> setProfile(PowerProfile p) async {
    final result = await ServicesScope.of(context).tools.setPowerProfile(p);
    if (!mounted) return;
    setState(
      () => error = result == null
          ? null
          : errorText(AppLocalizations.of(context), result),
    );
    await load();
  }
}

/// The idle times offered, in minutes; 0 is never.
const List<int> idleChoices = [1, 2, 5, 10, 15, 30, 60, 120, 180, 0];

/// A pop-up for one of power.json's idle times (`displayOffMinutes`, `sleepMinutes`).
Widget idleRow(
  BuildContext context, {
  required Key key,
  required String title,
  required String configKey,
  required VoidCallback changed,
}) {
  final l = AppLocalizations.of(context);
  final config = ServicesScope.of(context).config;
  final saved = config.idleMinutes(configKey).ceil();
  String label(int minutes) => minutes == 0
      ? l.lockNever
      : minutes % 60 == 0 && minutes >= 60
      ? l.lockHours(minutes ~/ 60)
      : l.lockMinutes(minutes);
  final choices = [
    for (final m in idleChoices.followedBy([saved]).toSet()) m,
  ]..sort((a, b) => (a == 0 ? 1 << 30 : a).compareTo(b == 0 ? 1 << 30 : b));
  return PopUpRow<int>(
    key: key,
    title: title,
    items: [for (final m in choices) PopUpItem(m, label(m))],
    value: saved,
    onChanged: (minutes) {
      config.writeIdleMinutes(configKey, minutes);
      changed();
    },
  );
}

/// When the display turns off, when the computer sleeps, and whether it may (power.json).
class SleepGroup extends StatefulWidget {
  const SleepGroup({super.key});

  @override
  State<SleepGroup> createState() => _SleepGroupState();
}

class _SleepGroupState extends State<SleepGroup> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    void changed() => setState(() {});
    return SystemStateBuilder(
      builder: (context, state) => SettingsGroup(
        children: [
          idleRow(
            context,
            key: const ValueKey('display off'),
            title: l.energyDisplayOff,
            configKey: 'displayOffMinutes',
            changed: changed,
          ),
          idleRow(
            context,
            key: const ValueKey('sleep after'),
            title: l.energySleep,
            configKey: 'sleepMinutes',
            changed: changed,
          ),
          SwitchRow(
            key: const ValueKey('prevent sleep'),
            title: l.energyPreventSleep,
            subtitle: state.inhibited ? l.energyInhibited : null,
            value: config.flag('power', 'preventSleep', fallback: false),
            onChanged: (on) {
              config.write('power', 'preventSleep', on);
              changed();
            },
          ),
        ],
      ),
    );
  }
}

class EnergyPane extends StatefulWidget {
  const EnergyPane({super.key});

  @override
  State<EnergyPane> createState() => _EnergyPaneState();
}

class _EnergyPaneState extends State<EnergyPane> with _PowerState {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profiles = power?.profiles ?? const <PowerProfile>[];
    return PanePage(
      children: [
        if (profiles.isNotEmpty)
          SettingsGroup(
            children: [
              PopUpRow<PowerProfile>(
                key: const ValueKey('power mode'),
                title: l.powerMode,
                subtitle: l.powerModeHelp,
                items: [
                  for (final p in profiles) PopUpItem(p, profileLabel(l, p)),
                ],
                value: power?.active,
                onChanged: setProfile,
              ),
            ],
          ),
        if (error case final e?) ErrorLine(e),
        const SleepGroup(),
        SettingsGroup(
          children: [
            if (wakeOnLan != null)
              SwitchRow(
                key: const ValueKey('wake for network'),
                title: l.energyWakeForNetwork,
                subtitle: l.energyWakeForNetworkHelp,
                value: wakeOnLan!,
                onChanged: setWakeOnLan,
              )
            else
              Unavailable(
                child: SwitchRow(
                  title: l.energyWakeForNetwork,
                  subtitle: l.energyWakeForNetworkNone,
                  value: false,
                ),
              ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.power,
          children: [
            SwitchRow(title: l.energyRestartAfterPowerFailure, value: false),
          ],
        ),
        if (power != null && profiles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              l.powerNoProfiles,
              style: settingsText(11, SettingsColors.of(context).secondary),
            ),
          ),
      ],
    );
  }
}

/// "3 h 20 min".
String formatDuration(AppLocalizations l, int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return hours > 0
      ? l.durationHoursMinutes(hours, minutes)
      : l.durationMinutes(minutes);
}

class BatteryPane extends StatefulWidget {
  const BatteryPane({super.key});

  @override
  State<BatteryPane> createState() => _BatteryPaneState();
}

class _BatteryPaneState extends State<BatteryPane> with _PowerState {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final profiles = power?.profiles ?? const <PowerProfile>[];
    final lowPower = power?.active == PowerProfile.powerSaver;
    return SystemStateBuilder(
      builder: (context, state) {
        final left = state.batteryCharging
            ? power?.secondsToFull ?? 0
            : power?.secondsToEmpty ?? 0;
        return PanePage(
          children: [
            SettingsGroup(
              children: [
                ValueRow(
                  key: const ValueKey('battery level'),
                  title: l.batteryLevel,
                  subtitle: [
                    state.batteryCharging
                        ? l.batteryCharging
                        : l.batteryOnBattery,
                    if (left > 0)
                      state.batteryCharging
                          ? l.batteryUntilFull(formatDuration(l, left))
                          : l.batteryLeft(formatDuration(l, left)),
                  ].join(' · '),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 140,
                        child: AmalfiProgressBar(
                          value: state.batteryPercent / 100,
                          semanticLabel: l.batteryLevel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.batteryPercent.round()} %',
                        style: settingsText(13, colors.text),
                      ),
                    ],
                  ),
                ),
                if ((power?.capacity ?? 0) > 0)
                  ValueRow(
                    key: const ValueKey('battery health'),
                    title: l.batteryHealth,
                    subtitle: l.batteryHealthHelp,
                    trailing: RowValue('${power!.capacity.round()} %'),
                  ),
              ],
            ),
            const SleepGroup(),
            SettingsGroup(
              children: [
                if (profiles.contains(PowerProfile.powerSaver))
                  SwitchRow(
                    key: const ValueKey('low power mode'),
                    title: l.batteryLowPowerMode,
                    subtitle: l.batteryLowPowerHelp,
                    value: lowPower,
                    onChanged: (on) => setProfile(
                      on ? PowerProfile.powerSaver : PowerProfile.balanced,
                    ),
                  )
                else
                  Unavailable(
                    child: SwitchRow(
                      title: l.batteryLowPowerMode,
                      value: false,
                    ),
                  ),
                Unavailable(
                  child: SwitchRow(
                    title: l.batteryOptimizedCharging,
                    value: false,
                  ),
                ),
              ],
              footer: l.notAvailableYet,
            ),
            if (error case final e?) ErrorLine(e),
          ],
        );
      },
    );
  }
}
