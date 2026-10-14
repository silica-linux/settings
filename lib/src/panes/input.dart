// Keyboard (ST-KBD-01..14), Mouse (ST-INP-01) and Printers and Scanners (ST-PRT-01).
// Real: the list of Silica's system shortcuts (read-only, the bindings of silica-desktop's
// command catalog); the CUPS printers (lpstat) and the default one (lpoptions). Ossido reads
// key repeat only from its environment at start: the sliders show the values in effect and
// wait for Ossido to read keyboard.json (#73). Input sources, dictation (#73), the pointer
// settings (#74) and adding printers (#56) wait for their backends.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';
import '../system/host.dart';
import '../model/issues.dart';
import '../ui/grouped.dart';

/// The key repeat rate slider's steps, in repeats per second; 0 turns repeat off. The
/// reference slider has 8 positions and does not expose its rate (ST-KBD-01): the values are
/// ours, provisional.
const List<int> repeatRateSteps = [0, 2, 6, 10, 15, 25, 30, 40];

/// The delay-until-repeat slider's steps, long to short, in ms (6 positions; values ours,
/// provisional).
const List<int> repeatDelaySteps = [1500, 1000, 800, 600, 400, 250];

/// The defaults: the reference machine read step 6 of the rate and step 4 of the delay
/// (1-based), which here are 25 per second and 600 ms.
const int defaultRepeatRate = 25;
const int defaultRepeatDelay = 600;

/// The step closest to [value].
int nearestStep(List<int> steps, int value) {
  var best = 0;
  for (var i = 1; i < steps.length; i++) {
    if ((steps[i] - value).abs() < (steps[best] - value).abs()) best = i;
  }
  return best;
}

class KeyboardPane extends StatefulWidget {
  const KeyboardPane({super.key});

  @override
  State<KeyboardPane> createState() => _KeyboardPaneState();
}

class _KeyboardPaneState extends State<KeyboardPane> {
  /// The repeat in effect: `OSSIDO_KEY_REPEAT` (`delay,rate`) when the session sets it,
  /// Ossido's defaults otherwise (375 ms, 11 per second).
  (int, int) _effective(Map<String, String> env) {
    final parts = (env['OSSIDO_KEY_REPEAT'] ?? '').split(',');
    if (parts.length == 2) {
      final delay = int.tryParse(parts[0].trim());
      final rate = int.tryParse(parts[1].trim());
      if (delay != null && rate != null && delay >= 0 && rate >= 0) {
        return (delay, rate);
      }
    }
    return (375, 11);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (delay, rate) = _effective(ServicesScope.of(context).env);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          issue: Issues.keyboard,
          footer: l.keyboardRepeatNow(rate, delay),
          children: [
            ValueRow(
              title: l.keyboardRepeatRate,
              height: 56,
              trailing: SilicaSlider(
                key: const ValueKey('repeat rate'),
                value: nearestStep(repeatRateSteps, rate).toDouble(),
                min: 0,
                max: repeatRateSteps.length - 1,
                divisions: repeatRateSteps.length - 1,
                ticks: true,
                labels: [l.keyboardOff, l.keyboardSlow, l.keyboardFast],
                width: 240,
                semanticLabel: l.keyboardRepeatRate,
                onChanged: (_) {},
              ),
            ),
            ValueRow(
              title: l.keyboardRepeatDelay,
              height: 56,
              trailing: SilicaSlider(
                key: const ValueKey('repeat delay'),
                value: nearestStep(repeatDelaySteps, delay).toDouble(),
                min: 0,
                max: repeatDelaySteps.length - 1,
                divisions: repeatDelaySteps.length - 1,
                ticks: true,
                labels: [l.keyboardLong, l.keyboardShort],
                width: 240,
                semanticLabel: l.keyboardRepeatDelay,
                onChanged: (_) {},
              ),
            ),
            PopUpRow<int>(
              title: l.keyboardGlobeKey,
              items: [PopUpItem(0, l.keyboardDoNothing)],
              value: 0,
              onChanged: (_) {},
            ),
            SwitchRow(title: l.keyboardNavigation, value: false),
          ],
        ),
        ButtonBar(
          buttons: [
            SilicaButton(
              key: const ValueKey('shortcuts'),
              label: l.keyboardShortcutsButton,
              size: ControlSize.small,
              onPressed: () => showShortcuts(context),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.keyboardTextInput,
          unavailable: true,
          issue: Issues.keyboard,
          children: [
            ButtonRow(
              title: l.keyboardInputSources,
              subtitle: l.keyboardInputSourcesValue,
              label: l.edit,
              onPressed: () {},
            ),
            ButtonRow(
              title: l.keyboardTextReplacements,
              label: l.edit,
              onPressed: () {},
            ),
          ],
        ),
        SettingsGroup(
          heading: l.keyboardDictation,
          unavailable: true,
          issue: Issues.keyboard,
          children: [SwitchRow(title: l.keyboardDictation, value: false)],
        ),
      ],
    );
  }
}

/// A system shortcut: its action and keys (silica-desktop's command catalog: ⌘ is the Logo key).
class SystemShortcut {
  const SystemShortcut(this.action, this.keys);
  final String action;
  final String keys;
}

/// Silica's system shortcuts by category.
List<(String, List<SystemShortcut>)> systemShortcuts(AppLocalizations l) => [
  (
    l.shortcutsScreenshots,
    [
      SystemShortcut(l.shortcutScreen, 'Logo ⇧ 3'),
      SystemShortcut(l.shortcutSelection, 'Logo ⇧ 4'),
      SystemShortcut(l.shortcutTools, 'Logo ⇧ 5'),
    ],
  ),
  (
    l.shortcutsSpaces,
    [
      SystemShortcut(l.shortcutPanorama, '⌃ ↑'),
      SystemShortcut(l.shortcutAppWindows, '⌃ ↓'),
      SystemShortcut(l.shortcutShowDesktop, 'F11'),
      SystemShortcut(l.shortcutPreviousSpace, '⌃ ←'),
      SystemShortcut(l.shortcutNextSpace, '⌃ →'),
    ],
  ),
  (
    l.shortcutsApps,
    [
      SystemShortcut(l.shortcutSearch, 'Logo Space'),
      SystemShortcut(l.shortcutNextApp, 'Logo ⇥'),
      SystemShortcut(l.shortcutPreviousApp, 'Logo ⇧ ⇥'),
      SystemShortcut(l.shortcutQuitApp, 'Logo Q'),
      SystemShortcut(l.shortcutForceQuit, 'Logo ⌥ Esc'),
    ],
  ),
  (
    l.shortcutsWindows,
    [
      SystemShortcut(l.shortcutCloseWindow, 'Logo W'),
      SystemShortcut(l.shortcutMinimize, 'Logo M'),
      SystemShortcut(l.shortcutFullScreen, 'Logo ⌃ F'),
    ],
  ),
  (l.shortcutsSession, [SystemShortcut(l.shortcutLogOut, 'Logo ⇧ Q')]),
];

/// The keyboard shortcuts sheet: categories on the left, the shortcuts on the right,
/// read-only (changing them has no backend yet).
Future<void> showShortcuts(BuildContext context) {
  final l = AppLocalizations.of(context);
  final categories = systemShortcuts(l);
  return showWindowSheet<void>(
    context,
    semanticLabel: l.keyboardShortcutsButton,
    builder: (context, sheet) =>
        _ShortcutsSheet(categories: categories, close: sheet.close),
  );
}

class _ShortcutsSheet extends StatefulWidget {
  const _ShortcutsSheet({required this.categories, required this.close});
  final List<(String, List<SystemShortcut>)> categories;
  final VoidCallback close;

  @override
  State<_ShortcutsSheet> createState() => _ShortcutsSheetState();
}

class _ShortcutsSheetState extends State<_ShortcutsSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    final (_, shortcuts) = widget.categories[_selected];
    return SizedBox(
      width: 680,
      height: 420,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 200,
                    child: ListView(
                      children: [
                        for (final (i, (name, _)) in widget.categories.indexed)
                          GestureDetector(
                            key: ValueKey('shortcut category $i'),
                            onTap: () => setState(() => _selected = i),
                            child: Container(
                              height: 28,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: i == _selected ? accent : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                name,
                                style: settingsText(
                                  13,
                                  i == _selected
                                      ? const Color(0xFFFFFFFF)
                                      : colors.text,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.group,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: [
                          for (final s in shortcuts)
                            ValueRow(
                              title: s.action,
                              trailing: Text(
                                s.keys,
                                style: settingsText(13, colors.secondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.shortcutsReadOnly,
                    style: settingsText(11, colors.secondary),
                  ),
                ),
                SilicaButton(
                  key: const ValueKey('shortcuts done'),
                  label: l.done,
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

class MousePane extends StatelessWidget {
  const MousePane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          issue: Issues.pointer,
          children: [
            SliderRow(
              title: l.mousePointerSpeed,
              value: 0.5,
              labels: [l.keyboardSlow, l.keyboardFast],
            ),
            SwitchRow(
              title: l.mouseNaturalScrolling,
              subtitle: l.mouseNaturalScrollingHelp,
              value: true,
            ),
            PopUpRow<int>(
              title: l.mouseSecondaryClick,
              items: [PopUpItem(0, l.mouseRightButton)],
              value: 0,
              onChanged: (_) {},
            ),
            SliderRow(
              title: l.mouseDoubleClickSpeed,
              value: 0.5,
              labels: [l.keyboardSlow, l.keyboardFast],
            ),
            SliderRow(
              title: l.mouseScrollSpeed,
              value: 0.5,
              labels: [l.keyboardSlow, l.keyboardFast],
            ),
          ],
        ),
      ],
    );
  }
}

class PrintersPane extends StatefulWidget {
  const PrintersPane({super.key});

  @override
  State<PrintersPane> createState() => _PrintersPaneState();
}

class _PrintersPaneState extends State<PrintersPane> {
  Future<List<Printer>>? _printers;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _printers ??= ServicesScope.of(context).host.printers();
  }

  /// Makes [name] the user's default printer (`lpoptions -d`, no administrator needed).
  Future<void> _setDefault(String name) async {
    final host = ServicesScope.of(context).host;
    final out = await host.run('lpoptions', ['-d', name]);
    if (!mounted) return;
    setState(() {
      _error = out == null
          ? AppLocalizations.of(context).printersDefaultFailed
          : null;
      _printers = host.printers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<Printer>>(
      future: _printers,
      builder: (context, snapshot) {
        final printers = snapshot.data ?? const <Printer>[];
        return PanePage(
          children: [
            SettingsGroup(
              children: [
                PopUpRow<String>(
                  key: const ValueKey('default printer'),
                  title: l.printersDefault,
                  items: [for (final p in printers) PopUpItem(p.name, p.name)],
                  value: printers.where((p) => p.isDefault).firstOrNull?.name,
                  onChanged: printers.isEmpty ? null : _setDefault,
                ),
                Unavailable(
                  child: PopUpRow<int>(
                    title: l.printersPaperSize,
                    items: const [PopUpItem(0, 'A4')],
                    value: 0,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            if (_error case final error?) ErrorLine(error),
            SettingsGroup(
              children: [
                if (printers.isEmpty)
                  EmptyState(l.printersNone)
                else
                  for (final p in printers)
                    ValueRow(
                      key: ValueKey('printer ${p.name}'),
                      title: p.name,
                      subtitle: p.isDefault ? l.printersIsDefault : null,
                    ),
              ],
            ),
            SettingsGroup(
              unavailable: true,
              issue: Issues.printers,
              children: [ButtonRow(title: l.printersAdd, label: l.addButton)],
            ),
          ],
        );
      },
    );
  }
}
