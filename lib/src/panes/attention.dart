// Notifications (ST-NTF-01), Sound (ST-SND-01), Focus (ST-FOC-01) and Screen Time (ST-SCT-01).
// Real: the output volume, mute and output device (PipeWire through silica-daemon) and Do Not
// Disturb. Alert sounds, input devices, per-app notification settings, the other focus modes
// and screen time have no backend yet.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../system/system.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

class NotificationsPane extends StatelessWidget {
  const NotificationsPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.notifications.symbol,
          tint: PaneId.notifications.tint,
          title: l.paneNotifications,
          description: l.notificationsDescription,
        ),
        SettingsGroup(
          heading: l.notificationsCenter,
          unavailable: true,
          children: [
            PopUpRow<int>(
              title: l.notificationsPreviews,
              items: [PopUpItem(0, l.notificationsWhenUnlocked)],
              value: 0,
            ),
            SwitchRow(title: l.notificationsWhenSleeping, value: false),
            SwitchRow(title: l.notificationsWhenLocked, value: true),
            SwitchRow(title: l.notificationsWhenMirroring, value: false),
          ],
        ),
        SettingsGroup(
          heading: l.notificationsApps,
          unavailable: true,
          children: [ValueRow(title: l.notificationsAppsNone)],
        ),
      ],
    );
  }
}

class SoundPane extends StatelessWidget {
  const SoundPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final system = ServicesScope.of(context).system;
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            heading: l.soundEffects,
            unavailable: true,
            children: [
              PopUpRow<int>(
                title: l.soundAlert,
                items: [PopUpItem(0, l.soundAlertDefault)],
                value: 0,
              ),
              SliderRow(title: l.soundAlertVolume, value: 0.75),
              SwitchRow(title: l.soundStartup, value: true),
              SwitchRow(title: l.soundInterface, value: true),
              SwitchRow(title: l.soundVolumeFeedback, value: false),
            ],
          ),
          SettingsGroup(
            heading: l.soundOutput,
            footer: state.audioAvailable ? null : l.soundNoAudio,
            children: [
              _OutputDevices(
                key: ValueKey(state.audioName),
                system: system,
                enabled: state.audioAvailable,
              ),
            ],
          ),
          SettingsGroup(
            children: [
              ValueRow(
                title: l.soundOutputVolume,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SilicaSlider(
                      key: const ValueKey('output volume'),
                      value: state.volume,
                      width: 220,
                      enabled: state.audioAvailable,
                      semanticLabel: l.soundOutputVolume,
                      onChanged: state.audioAvailable
                          ? (v) => system.setVolume(v)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    SilicaCheckbox(
                      key: const ValueKey('mute'),
                      value: state.muted,
                      label: l.soundMute,
                      onChanged: state.audioAvailable
                          ? (v) => system.setMuted(v)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SettingsGroup(
            heading: l.soundInput,
            unavailable: true,
            children: [SliderRow(title: l.soundInputLevel, value: 0.5)],
          ),
        ],
      ),
    );
  }
}

class _OutputDevices extends StatefulWidget {
  const _OutputDevices({
    super.key,
    required this.system,
    required this.enabled,
  });

  final SystemBackend system;
  final bool enabled;

  @override
  State<_OutputDevices> createState() => _OutputDevicesState();
}

class _OutputDevicesState extends State<_OutputDevices> {
  late Future<List<AudioOutput>> _outputs = widget.system.audioOutputs();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<AudioOutput>>(
      future: _outputs,
      builder: (context, snapshot) {
        final outputs = snapshot.data ?? const <AudioOutput>[];
        final chosen = outputs.where((o) => o.isDefault).firstOrNull;
        return PopUpRow<int>(
          key: const ValueKey('output device'),
          title: l.soundOutputDevice,
          items: [for (final o in outputs) PopUpItem(o.id, o.name)],
          value: chosen?.id,
          onChanged: widget.enabled && outputs.isNotEmpty
              ? (id) async {
                  await widget.system.setAudioOutput(id);
                  if (mounted) {
                    setState(() {
                      _outputs = widget.system.audioOutputs();
                    });
                  }
                }
              : null,
        );
      },
    );
  }
}

class FocusPane extends StatelessWidget {
  const FocusPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final system = ServicesScope.of(context).system;
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            footer: state.reachable ? null : l.appearanceNoDaemon,
            children: [
              ValueRow(
                title: l.focusDoNotDisturb,
                height: 52,
                leading: const IconTile(
                  symbol: 'moon',
                  tint: Color(0xFF5E5CE6),
                  size: 32,
                ),
                trailing: SilicaSwitch(
                  key: const ValueKey('dnd switch'),
                  value: state.doNotDisturb,
                  size: ControlSize.mini,
                  semanticLabel: l.focusDoNotDisturb,
                  onChanged: state.reachable
                      ? (on) => system.setDoNotDisturb(on)
                      : null,
                ),
              ),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            children: [
              for (final (title, symbol, tint) in [
                (l.focusWork, 'person', const Color(0xFF30B0C7)),
                (
                  l.focusReduceInterruptions,
                  'bell-slash',
                  const Color(0xFF5E5CE6),
                ),
                (l.focusSleep, 'moon-stars', const Color(0xFF34C759)),
                (l.focusStudy, 'lightbulb', const Color(0xFFFF9500)),
              ])
                NavRow(title: title, symbol: symbol, tint: tint),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            children: [
              SwitchRow(title: l.focusShareAcrossDevices, value: false),
              NavRow(title: l.focusStatus, value: l.on),
            ],
          ),
        ],
      ),
    );
  }
}

class ScreenTimePane extends StatelessWidget {
  const ScreenTimePane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.screenTimeActivity,
          unavailable: true,
          children: [
            NavRow(title: l.screenTimeAppUsage, symbol: 'hourglass'),
            NavRow(title: l.screenTimeNotifications, symbol: 'bell'),
          ],
        ),
        SettingsGroup(
          heading: l.screenTimeLimits,
          unavailable: true,
          children: [
            NavRow(title: l.screenTimeDowntime, symbol: 'moon'),
            NavRow(title: l.screenTimeAppLimits, symbol: 'hourglass'),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [SwitchRow(title: l.screenTimeAppActivity, value: false)],
        ),
      ],
    );
  }
}
