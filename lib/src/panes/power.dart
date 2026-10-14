// Energy (ST-PWR-01: three switches) and Battery (machines with a battery: the level and the
// charge from UPower, through silica-daemon). The power policies have no backend yet.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';
import '../ui/grouped.dart';

class EnergyPane extends StatelessWidget {
  const EnergyPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          children: [
            SwitchRow(title: l.energyPreventSleep, value: false),
            SwitchRow(title: l.energyWakeForNetwork, value: false),
            SwitchRow(title: l.energyRestartAfterPowerFailure, value: false),
          ],
        ),
      ],
    );
  }
}

class BatteryPane extends StatelessWidget {
  const BatteryPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            children: [
              ValueRow(
                key: const ValueKey('battery level'),
                title: l.batteryLevel,
                subtitle: state.batteryCharging
                    ? l.batteryCharging
                    : l.batteryOnBattery,
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    children: [
                      SilicaProgressBar(
                        value: state.batteryPercent / 100,
                        width: 110,
                        semanticLabel: l.batteryLevel,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.batteryPercent.round()} %',
                        style: settingsText(
                          13,
                          SettingsColors.of(context).text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            children: [
              SwitchRow(title: l.batteryLowPowerMode, value: false),
              SwitchRow(title: l.batteryOptimizedCharging, value: false),
            ],
          ),
        ],
      ),
    );
  }
}
