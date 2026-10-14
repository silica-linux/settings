// Appearance (ST-APP-01..04): light / dark / automatic previews (74 × 66), the glass card,
// the theme (nine accent swatches 32 pt apart, highlight, icon style, folder colour) and the
// window options. Light and dark go through silica-daemon (SetDark: Ossido, the shell, the apps
// and the portal follow); the accent is saved in theme.json and drawn by this window, the
// other components will read it from there. Automatic mode, glass opacity, icon styles and
// the window options have no backend yet.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../accent.dart';
import '../services.dart';
import '../style.dart';
import '../ui/grouped.dart';

enum AppearanceMode { light, dark, automatic }

class AppearancePane extends StatelessWidget {
  const AppearancePane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    return SystemStateBuilder(
      builder: (context, state) => PanePage(
        children: [
          SettingsGroup(
            footer: state.reachable ? null : l.appearanceNoDaemon,
            children: [
              ValueRow(
                title: l.appearanceMode,
                height: 112,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in AppearanceMode.values) ...[
                      if (mode != AppearanceMode.light)
                        const SizedBox(width: 12),
                      _ModePreview(
                        key: ValueKey('mode ${mode.name}'),
                        mode: mode,
                        label: switch (mode) {
                          AppearanceMode.light => l.appearanceLight,
                          AppearanceMode.dark => l.appearanceDark,
                          AppearanceMode.automatic => l.appearanceAuto,
                        },
                        selected: switch (mode) {
                          AppearanceMode.light => !state.dark,
                          AppearanceMode.dark => state.dark,
                          AppearanceMode.automatic => false,
                        },
                        // Automatic needs a schedule in the daemon (not yet).
                        onTap:
                            !state.reachable || mode == AppearanceMode.automatic
                            ? null
                            : () => services.system.setDark(
                                mode == AppearanceMode.dark,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SettingsGroup(
            heading: l.appearanceTheme,
            children: [
              ValueRow(
                title: l.appearanceAccent,
                height: 64,
                trailing: ValueListenableBuilder<Accent>(
                  valueListenable: services.accent,
                  builder: (context, accent, _) => _AccentPicker(
                    value: accent,
                    onChanged: services.setAccent,
                  ),
                ),
              ),
            ],
          ),
          SettingsGroup(
            unavailable: true,
            children: [
              PopUpRow<int>(
                title: l.appearanceHighlight,
                items: [PopUpItem(0, l.appearanceAutomaticChoice)],
                value: 0,
              ),
              PopUpRow<int>(
                title: l.appearanceIconStyle,
                items: [PopUpItem(0, l.appearanceDefaultChoice)],
                value: 0,
              ),
              PopUpRow<int>(
                title: l.appearanceFolderColor,
                items: [PopUpItem(0, l.appearanceAutomaticChoice)],
                value: 0,
              ),
              SliderRow(title: l.appearanceGlass, value: 0.5),
            ],
          ),
          SettingsGroup(
            heading: l.appearanceWindows,
            unavailable: true,
            children: [
              PopUpRow<int>(
                title: l.appearanceSidebarIconSize,
                items: [PopUpItem(0, l.appearanceMedium)],
                value: 0,
              ),
              SwitchRow(title: l.appearanceTint, value: false),
              PopUpRow<int>(
                title: l.appearanceScrollBars,
                items: [PopUpItem(0, l.appearanceScrollAuto)],
                value: 0,
              ),
              PopUpRow<int>(
                title: l.appearanceScrollClick,
                items: [PopUpItem(0, l.appearanceScrollNextPage)],
                value: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 74 × 66 preview of a mode with its label; the chosen one has an accent ring.
class _ModePreview extends StatelessWidget {
  const _ModePreview({
    super.key,
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppearanceMode mode;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    Widget half(bool dark) => ColoredBox(
      color: dark ? const Color(0xFF1E1E1F) : const Color(0xFFF2F2F4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 0, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 52,
            height: 34,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF3A3A3C) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(5),
            child: Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null && !selected ? 0.5 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74 + 6,
                height: 66 + 6,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected ? accent : const Color(0x00000000),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: switch (mode) {
                    AppearanceMode.light => half(false),
                    AppearanceMode.dark => half(true),
                    AppearanceMode.automatic => Row(
                      children: [
                        Expanded(child: ClipRect(child: half(false))),
                        Expanded(child: ClipRect(child: half(true))),
                      ],
                    ),
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: settingsText(
                  11,
                  colors.text,
                  weight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The nine accent swatches, 32 pt apart (ST-APP-02); the chosen one has a white centre and its
/// name below.
class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.value, required this.onChanged});

  final Accent value;
  final ValueChanged<Accent> onChanged;

  static String name(AppLocalizations l, Accent a) => switch (a) {
    Accent.multicolour => l.accentMulticolour,
    Accent.blue => l.accentBlue,
    Accent.purple => l.accentPurple,
    Accent.pink => l.accentPink,
    Accent.red => l.accentRed,
    Accent.orange => l.accentOrange,
    Accent.yellow => l.accentYellow,
    Accent.green => l.accentGreen,
    Accent.graphite => l.accentGraphite,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final dark = colors.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final accent in Accent.values)
              SizedBox(
                width: 32,
                child: Center(
                  child: Semantics(
                    button: true,
                    selected: accent == value,
                    label: name(l, accent),
                    child: GestureDetector(
                      key: ValueKey('accent ${accent.name}'),
                      onTap: () => onChanged(accent),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: accent == Accent.multicolour
                              ? const SweepGradient(
                                  colors: [
                                    Color(0xFFFF3B30),
                                    Color(0xFFFFCC00),
                                    Color(0xFF34C759),
                                    Color(0xFF0A84FF),
                                    Color(0xFFAF52DE),
                                    Color(0xFFFF3B30),
                                  ],
                                )
                              : null,
                          color: accent == Accent.multicolour
                              ? null
                              : accent.plain(dark: dark),
                        ),
                        alignment: Alignment.center,
                        child: accent == value
                            ? Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFFFFF),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name(l, value),
          key: const ValueKey('accent name'),
          style: settingsText(11, colors.secondary),
        ),
      ],
    );
  }
}
