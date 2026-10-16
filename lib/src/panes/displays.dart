// Displays (ST-DSP-01..03, SH-NS-01): the connected displays as thumbnails, and for the one
// chosen its resolution, refresh rate, scale and rotation, changed through silica-daemon
// (`ConfigureOutput`: Ossido applies it at once and keeps it per display, #63). A change that
// could leave the screen unreadable asks "Keep these settings?" and goes back by itself after
// 15 seconds. Night light is the daemon's (`SetNightLight`, nightlight.json), with a schedule.
// When the compositor reports no display (nothing answers) the pane falls back to what the
// machine lists in /sys/class/drm, read-only. The arrangement, the colour profile and the main
// display wait for their backends (#63).

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../services.dart';
import '../style.dart';
import '../system/displays.dart';
import '../system/system.dart';
import '../system/tools.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

/// `2560x1440` → `2560 × 1440`.
String modeLabel(String mode) => mode.replaceFirst('x', ' × ');

/// How long the "Keep these settings?" sheet waits before it puts the display back.
const Duration keepDisplayFor = Duration(seconds: 15);

/// The scales Ossido takes: 1 to 4 in quarter steps.
final List<double> scaleSteps = [for (var i = 4; i <= 16; i++) i / 4];

/// The rotations Settings offers, as Ossido names them.
const List<String> rotations = ['normal', '90', '180', '270'];

/// `1.5`, `2`, `1.25`: no needless zeros.
String trimmed(double value) {
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

class DisplaysPane extends StatefulWidget {
  const DisplaysPane({super.key});

  @override
  State<DisplaysPane> createState() => _DisplaysPaneState();
}

class _DisplaysPaneState extends State<DisplaysPane> {
  /// What `Outputs()` answered at the start, until the state carries the displays.
  List<OutputInfo> _fetched = const [];

  /// /sys/class/drm: shown only when the compositor reports nothing.
  List<DisplayOutput>? _listed;
  String _chosen = '';
  String? _error;
  bool _busy = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final services = ServicesScope.of(context);
      services.system.displayList().then((list) {
        if (mounted) setState(() => _fetched = list);
      });
      services.tools.displays().then((list) {
        if (mounted) setState(() => _listed = list);
      });
    }
  }

  /// Applies one change to [display] and, when the person does not confirm it, puts the display
  /// back as it was.
  Future<void> _change(
    OutputInfo display, {
    OutputMode? mode,
    double? scale,
    String? transform,
  }) async {
    final system = ServicesScope.of(context).system;
    final l = AppLocalizations.of(context);
    final before = display.current;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await system.configureOutput(
      display.connector,
      mode: mode,
      scale: scale,
      transform: transform,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = l.displaysChangeFailed(error);
      });
      return;
    }
    setState(() => _busy = false);
    final keep = await showWindowSheet<bool>(
      context,
      semanticLabel: l.displaysKeepTitle,
      cancelOnEscape: false,
      builder: (context, sheet) => _KeepSheet(close: sheet.close),
    );
    if (keep == true) return;
    // Not confirmed, or the time ran out: the display as it was.
    final back = await system.configureOutput(
      display.connector,
      mode: before,
      scale: display.scale,
      transform: display.transform,
    );
    if (mounted && back != null) {
      setState(() => _error = l.displaysChangeFailed(back));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return SystemStateBuilder(
      builder: (context, state) {
        final reported = OutputInfo.parseList(state.displays);
        final live = reported.isNotEmpty ? reported : _fetched;
        final listed = _listed;
        // Thumbnails: the compositor's displays, otherwise the machine's.
        final names = live.isNotEmpty
            ? [for (final o in live) (o.connector, o.name)]
            : [
                for (final o in listed ?? const <DisplayOutput>[])
                  (o.connector, o.connector),
              ];
        final chosenName = names.any((n) => n.$1 == _chosen)
            ? _chosen
            : (names.isEmpty ? '' : names.first.$1);
        final display = live
            .where((o) => o.connector == chosenName)
            .firstOrNull;
        return PanePage(
          children: [
            // The displays, as thumbnails with their names (ST-DSP-02).
            SizedBox(
              height: 112,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (connector, name) in names)
                      GestureDetector(
                        key: ValueKey('display $connector'),
                        onTap: () => setState(() => _chosen = connector),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: connector == chosenName
                                        ? ControlAccent.of(context)
                                        : const Color(0xFF1C1C1E),
                                    width: 3,
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8EC5FF),
                                      Color(0xFFF9C6D9),
                                      Color(0xFFFFE2B0),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: settingsText(
                                  13,
                                  colors.text,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (names.isEmpty && listed != null)
                      Text(
                        l.displaysNone,
                        style: settingsText(13, colors.secondary),
                      ),
                  ],
                ),
              ),
            ),
            if (display != null)
              ..._live(context, display, state)
            else
              ..._listedOnly(
                context,
                listed?.where((o) => o.connector == chosenName).firstOrNull,
              ),
          ],
        );
      },
    );
  }

  /// The controls of a display the compositor drives.
  List<Widget> _live(
    BuildContext context,
    OutputInfo display,
    SystemState state,
  ) {
    final l = AppLocalizations.of(context);
    final canChange = display.enabled && !_busy;
    final current = display.current;
    final sizes = display.sizes;
    final currentSize = current?.size;
    final refreshes = currentSize == null
        ? const <double>[]
        : display.refreshesAt(currentSize);
    final refresh = current == null || refreshes.isEmpty
        ? null
        : refreshes.reduce(
            (a, b) => (a - current.refresh).abs() <= (b - current.refresh).abs()
                ? a
                : b,
          );
    final scales = {...scaleSteps, display.scale}.toList()..sort();
    final rotationItems = {...rotations, display.transform}.toList();
    String rotationLabel(String t) => switch (t) {
      'normal' => l.displaysStandard,
      '90' => l.displaysRotate90,
      '180' => l.displaysRotate180,
      '270' => l.displaysRotate270,
      _ => t,
    };
    final night = state.night;
    return [
      SettingsGroup(
        footer: display.enabled ? null : l.displaysOnlyActive,
        children: [
          Unavailable(
            child: PopUpRow<int>(
              title: l.displaysUseAs,
              items: [PopUpItem(0, l.displaysMain)],
              value: 0,
              onChanged: (_) {},
            ),
          ),
          PopUpRow<String>(
            key: const ValueKey('display resolution'),
            title: l.displaysResolution,
            items: [
              for (final m in sizes)
                PopUpItem(
                  m.size,
                  m.preferred
                      ? l.displaysDefaultMode(modeLabel(m.size))
                      : modeLabel(m.size),
                ),
            ],
            value: currentSize,
            onChanged: canChange
                ? (size) {
                    if (size == currentSize) return;
                    // The mode of that size nearest to the refresh in use.
                    final candidates = display.modes
                        .where((m) => m.size == size)
                        .toList();
                    if (candidates.isEmpty) return;
                    final want = current?.refresh ?? 0;
                    final mode = candidates.reduce(
                      (a, b) =>
                          (a.refresh - want).abs() <= (b.refresh - want).abs()
                          ? a
                          : b,
                    );
                    _change(display, mode: mode);
                  }
                : null,
          ),
          PopUpRow<double>(
            key: const ValueKey('display refresh'),
            title: l.displaysRefreshRate,
            items: [
              for (final r in refreshes) PopUpItem(r, l.displaysHz(trimmed(r))),
            ],
            value: refresh,
            onChanged: canChange && current != null
                ? (rate) {
                    if (rate == refresh) return;
                    _change(
                      display,
                      mode: OutputMode(
                        width: current.width,
                        height: current.height,
                        refresh: rate,
                      ),
                    );
                  }
                : null,
          ),
          PopUpRow<double>(
            key: const ValueKey('display scale'),
            title: l.displaysScale,
            items: [
              for (final s in scales)
                PopUpItem(s, l.displaysScaleValue(trimmed(s))),
            ],
            value: display.scale,
            onChanged: canChange
                ? (scale) {
                    if (scale != display.scale) _change(display, scale: scale);
                  }
                : null,
          ),
          PopUpRow<String>(
            key: const ValueKey('display rotation'),
            title: l.displaysRotation,
            items: [
              for (final t in rotationItems) PopUpItem(t, rotationLabel(t)),
            ],
            value: display.transform,
            onChanged: canChange
                ? (transform) {
                    if (transform != display.transform) {
                      _change(display, transform: transform);
                    }
                  }
                : null,
          ),
        ],
      ),
      if (_error case final error?) ErrorLine(error),
      SettingsGroup(
        unavailable: true,
        issue: Issues.displays,
        children: [
          PopUpRow<int>(
            title: l.displaysColorProfile,
            items: [PopUpItem(0, l.appearanceDefaultChoice)],
            value: 0,
            onChanged: (_) {},
          ),
        ],
      ),
      SettingsGroup(
        footer: night.active ? l.displaysNightActive : null,
        children: [
          ButtonRow(
            key: const ValueKey('night light'),
            title: l.displaysNightLight,
            subtitle: !night.enabled
                ? l.displaysNightOff
                : switch (night.schedule) {
                    'sunset' => l.displaysNightSunset,
                    'custom' => l.displaysNightOnCustom(night.from, night.to),
                    _ => l.displaysNightOnAllDay,
                  },
            label: l.displaysNightLightButton,
            onPressed: () => showNightLight(context),
          ),
        ],
      ),
    ];
  }

  /// What the machine lists when the compositor reports nothing: read-only.
  List<Widget> _listedOnly(BuildContext context, DisplayOutput? chosen) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final flutterDisplays = PlatformDispatcher.instance.displays.toList();
    final current = flutterDisplays.isEmpty ? null : flutterDisplays.first;
    final currentMode = current == null
        ? ''
        : '${current.size.width.round()}x${current.size.height.round()}';
    return [
      if (chosen != null)
        SettingsGroup(
          footer: [l.displaysModesHelp, l.displaysNoCompositor].join(' '),
          children: [
            for (final (i, mode) in chosen.modes.take(8).indexed)
              ValueRow(
                key: ValueKey('mode $mode'),
                title: i == 0
                    ? l.displaysDefaultMode(modeLabel(mode))
                    : modeLabel(mode),
                trailing: mode == currentMode || (currentMode.isEmpty && i == 0)
                    ? SettingsSymbol('checkmark', color: colors.text, size: 12)
                    : null,
              ),
          ],
        ),
      SettingsGroup(
        footer: l.displaysNow,
        children: [
          ValueRow(
            key: const ValueKey('display resolution'),
            title: l.displaysResolution,
            trailing: RowValue(
              current == null ? l.aboutUnknown : modeLabel(currentMode),
            ),
          ),
          ValueRow(
            title: l.displaysScale,
            trailing: RowValue(
              current == null
                  ? l.aboutUnknown
                  : l.displaysScaleValue(trimmed(current.devicePixelRatio)),
            ),
          ),
          ValueRow(
            title: l.displaysRefreshRate,
            trailing: RowValue(
              current != null && current.refreshRate > 0
                  ? l.displaysHz('${current.refreshRate.round()}')
                  : l.aboutUnknown,
            ),
          ),
        ],
      ),
    ];
  }
}

/// "Keep these display settings?": Keep (true) or Revert (false); when the time runs out it
/// closes as if Revert was pressed.
class _KeepSheet extends StatefulWidget {
  const _KeepSheet({required this.close});
  final void Function([bool?]) close;

  @override
  State<_KeepSheet> createState() => _KeepSheetState();
}

class _KeepSheetState extends State<_KeepSheet> {
  late int _left = keepDisplayFor.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _timer?.cancel();
        widget.close(false);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.displaysKeepTitle,
              style: settingsText(13, colors.text, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l.displaysKeepBody(_left),
              key: const ValueKey('keep countdown'),
              style: settingsText(13, colors.secondary, height: 1.3),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AmalfiPushButton(
                  key: const ValueKey('revert display'),
                  label: l.displaysRevert,
                  onPressed: () => widget.close(false),
                ),
                const SizedBox(width: 8),
                AmalfiPushButton(
                  key: const ValueKey('keep display'),
                  label: l.displaysKeep,
                  variant: AmalfiPushButtonVariant.primary,
                  onPressed: () => widget.close(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Night light (SH-NS-01): on or off, the schedule, its times and the colour temperature.
Future<void> showNightLight(BuildContext context) => showWindowSheet<void>(
  context,
  semanticLabel: AppLocalizations.of(context).displaysNightLight,
  builder: (context, sheet) => _NightLightSheet(close: sheet.close),
);

class _NightLightSheet extends StatefulWidget {
  const _NightLightSheet({required this.close});
  final VoidCallback close;

  @override
  State<_NightLightSheet> createState() => _NightLightSheetState();
}

class _NightLightSheetState extends State<_NightLightSheet> {
  late final TextEditingController _from;
  late final TextEditingController _to;
  String? _error;
  double? _dragging;

  @override
  void initState() {
    super.initState();
    _from = TextEditingController();
    _to = TextEditingController();
  }

  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      _seeded = true;
      // The daemon's current times fill the fields once; typing is the person's after that.
      ServicesScope.of(context).system.state().then((state) {
        if (!mounted) return;
        _from.text = state.night.from;
        _to.text = state.night.to;
      });
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  /// Sends one setting; a refusal is said under the controls.
  Future<void> _set({
    bool? enabled,
    int? temperature,
    String? schedule,
    String? from,
    String? to,
  }) async {
    final l = AppLocalizations.of(context);
    final error = await ServicesScope.of(context).system.setNightLight(
      enabled: enabled,
      temperature: temperature,
      schedule: schedule,
      from: from,
      to: to,
    );
    if (mounted) {
      setState(
        () => _error = error == null ? null : l.displaysNightFailed(error),
      );
    }
  }

  /// 0 (neutral, 6500 K) to 1 (the warmest, 1900 K).
  static double warmth(int kelvin) =>
      (NightLight.maxTemperature - kelvin) /
      (NightLight.maxTemperature - NightLight.minTemperature);

  static int kelvinOf(double warmth) =>
      (NightLight.maxTemperature -
              warmth.clamp(0, 1) *
                  (NightLight.maxTemperature - NightLight.minTemperature))
          .round();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return SystemStateBuilder(
      builder: (context, state) {
        final night = state.night;
        final badTimes =
            night.schedule == 'custom' &&
            (!NightLight.validTime(_from.text) ||
                !NightLight.validTime(_to.text));
        return SizedBox(
          width: 528,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.displaysNightLight,
                  style: settingsText(13, colors.text, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GroupBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchRow(
                        key: const ValueKey('night enabled'),
                        title: l.displaysNightLight,
                        value: night.enabled,
                        onChanged: (on) => _set(enabled: on),
                      ),
                      const RowSeparator(),
                      PopUpRow<String>(
                        key: const ValueKey('night schedule'),
                        title: l.displaysNightSchedule,
                        items: [
                          PopUpItem('off', l.displaysNightAllDay),
                          PopUpItem('sunset', l.displaysNightSunset),
                          PopUpItem('custom', l.displaysNightCustom),
                        ],
                        value: night.schedule,
                        onChanged: (schedule) => _set(schedule: schedule),
                      ),
                      if (night.schedule == 'custom') ...[
                        const RowSeparator(),
                        ValueRow(
                          title: l.displaysNightFrom,
                          trailing: SizedBox(
                            width: 90,
                            child: AmalfiTextField(
                              key: const ValueKey('night from'),
                              controller: _from,
                              semanticLabel: l.displaysNightFrom,
                              onChanged: (v) {
                                setState(() {});
                                if (NightLight.validTime(v)) _set(from: v);
                              },
                            ),
                          ),
                        ),
                        const RowSeparator(),
                        ValueRow(
                          title: l.displaysNightTo,
                          trailing: SizedBox(
                            width: 90,
                            child: AmalfiTextField(
                              key: const ValueKey('night to'),
                              controller: _to,
                              semanticLabel: l.displaysNightTo,
                              onChanged: (v) {
                                setState(() {});
                                if (NightLight.validTime(v)) _set(to: v);
                              },
                            ),
                          ),
                        ),
                      ],
                      const RowSeparator(),
                      SliderRow(
                        key: const ValueKey('night temperature'),
                        title: l.displaysNightTemperature,
                        value: _dragging ?? warmth(night.temperature),
                        labels: [l.displaysNightLess, l.displaysNightMore],
                        width: 240,
                        onChanged: (v) => setState(() => _dragging = v),
                        onChangeEnd: (end) async {
                          // The last position dragged to, which the slider may not have
                          // been rebuilt with yet.
                          final v = _dragging ?? end;
                          setState(() => _dragging = null);
                          await _set(temperature: kelvinOf(v));
                        },
                      ),
                    ],
                  ),
                ),
                if (badTimes || _error != null || night.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      badTimes
                          ? l.displaysNightBadTime
                          : (_error ?? l.displaysNightActive),
                      key: badTimes || _error != null
                          ? const ValueKey('error')
                          : const ValueKey('night active'),
                      style: settingsText(
                        11,
                        badTimes || _error != null
                            ? const Color(0xFFE0393E)
                            : colors.secondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AmalfiPushButton(
                      key: const ValueKey('night done'),
                      label: l.done,
                      variant: AmalfiPushButtonVariant.primary,
                      onPressed: widget.close,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
