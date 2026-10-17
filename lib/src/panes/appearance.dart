// Appearance (ST-APP-01..04): light / dark / automatic previews, the theme (nine accent
// swatches 36 pt apart, highlight colour, icon style, folder colour) and the window options.
// Light, dark and automatic go through silica-daemon (SetAppearanceMode: automatic follows the
// sun, the daemon turns dark on at sunset; Ossido, the shell, the apps and the portal follow).
// The look is saved in theme.json and told to silica-daemon (SetLook): this window, the other
// apps (silica_ui's SystemLookScope), the shell and the compositor (the glass) follow live
// (#59, #80). The folder colour and the window tint wait for their backends (#60).

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
      builder: (context, state) {
        // A daemon without a mode (older) tells light from dark only.
        final chosen = switch (state.appearanceMode) {
          'auto' => AppearanceMode.automatic,
          'dark' => AppearanceMode.dark,
          'light' => AppearanceMode.light,
          _ => state.dark ? AppearanceMode.dark : AppearanceMode.light,
        };
        return ListenableBuilder(
          listenable: services.look,
          builder: (context, _) => PanePage(
            children: [
              _ModeSection(
                note: state.reachable
                    ? l.appearanceAutoNote
                    : l.appearanceNoDaemon,
                children: [
                  for (final mode in AppearanceMode.values)
                    _ModePreview(
                      key: ValueKey('mode ${mode.name}'),
                      mode: mode,
                      label: switch (mode) {
                        AppearanceMode.light => l.appearanceLight,
                        AppearanceMode.dark => l.appearanceDark,
                        AppearanceMode.automatic => l.appearanceAuto,
                      },
                      selected: mode == chosen,
                      onTap: state.reachable
                          ? () => services.system.setAppearanceMode(
                              switch (mode) {
                                AppearanceMode.light => 'light',
                                AppearanceMode.dark => 'dark',
                                AppearanceMode.automatic => 'auto',
                              },
                            )
                          : null,
                    ),
                ],
              ),
              SettingsGroup(
                heading: l.appearanceGlass,
                children: [
                  SliderRow(
                    key: const ValueKey('glass'),
                    title: l.appearanceGlass,
                    value: services.glass.value,
                    labels: [l.appearanceGlassClear, l.appearanceGlassTinted],
                    onChanged: services.setGlass,
                  ),
                ],
              ),
              SettingsGroup(
                heading: l.appearanceTheme,
                footer: l.appearanceThemeNote,
                children: [
                  ValueRow(
                    title: l.appearanceAccent,
                    alignTop: true,
                    trailing: _AccentPicker(
                      value: services.accent.value,
                      onChanged: services.setAccent,
                    ),
                  ),
                  PopUpRow<IconStyle>(
                    key: const ValueKey('icon style'),
                    title: l.appearanceIconStyle,
                    items: [
                      PopUpItem(IconStyle.standard, l.appearanceStyleDefault),
                      PopUpItem(IconStyle.dark, l.appearanceStyleDark),
                      PopUpItem(IconStyle.clear, l.appearanceStyleClear),
                      PopUpItem(IconStyle.tinted, l.appearanceStyleTinted),
                    ],
                    value: services.iconStyle.value,
                    onChanged: services.setIconStyle,
                  ),
                  PopUpRow<HighlightColor>(
                    key: const ValueKey('highlight'),
                    title: l.appearanceHighlight,
                    items: [
                      PopUpItem(
                        HighlightColor.automatic,
                        l.appearanceAutomaticChoice,
                      ),
                      for (final accent in Accent.values.skip(1))
                        PopUpItem(
                          HighlightColor.values.byName(accent.name),
                          _AccentPicker.name(l, accent),
                        ),
                    ],
                    value: services.highlight.value,
                    onChanged: services.setHighlight,
                    leading:
                        services.highlight.value == HighlightColor.automatic
                        ? const _Swatch(gradient: true)
                        : _Swatch(
                            color: Accent.parse(
                              services.highlight.value.name,
                            ).plain(dark: SettingsColors.of(context).dark),
                          ),
                  ),
                  Unavailable(
                    child: PopUpRow<int>(
                      title: l.appearanceFolderColor,
                      items: [PopUpItem(0, l.appearanceAutomaticChoice)],
                      value: 0,
                      onChanged: (_) {},
                      leading: _Swatch(color: Accent.blue.plain(dark: false)),
                    ),
                  ),
                ],
              ),
              SettingsGroup(
                heading: l.appearanceWindows,
                footer: l.appearanceNoTintYet,
                children: [
                  PopUpRow<SidebarIconSize>(
                    key: const ValueKey('sidebar icon size'),
                    title: l.appearanceSidebarIconSize,
                    items: [
                      PopUpItem(SidebarIconSize.small, l.appearanceSmall),
                      PopUpItem(SidebarIconSize.medium, l.appearanceMedium),
                      PopUpItem(SidebarIconSize.large, l.appearanceLarge),
                    ],
                    value: services.sidebarIconSize.value,
                    onChanged: services.setSidebarIconSize,
                  ),
                  Unavailable(
                    child: SwitchRow(title: l.appearanceTint, value: false),
                  ),
                ],
              ),
              SettingsGroup(
                heading: l.appearanceScrollBars,
                footer: l.appearanceOtherApps,
                children: [
                  for (final (mode, label) in [
                    (ScrollBarsMode.automatic, l.appearanceScrollAuto),
                    (
                      ScrollBarsMode.whenScrolling,
                      l.appearanceScrollWhenScrolling,
                    ),
                    (ScrollBarsMode.always, l.appearanceScrollAlways),
                  ])
                    RadioRow(
                      key: ValueKey('scroll bars ${mode.name}'),
                      label: label,
                      selected: services.scrollBars.value == mode,
                      onSelected: () => services.setScrollBars(mode),
                    ),
                ],
              ),
              SettingsGroup(
                heading: l.appearanceScrollClick,
                footer: l.appearanceOtherApps,
                children: [
                  RadioRow(
                    key: const ValueKey('scroll click page'),
                    label: l.appearanceScrollNextPage,
                    selected: services.scrollClick.value == ScrollClick.page,
                    onSelected: () => services.setScrollClick(ScrollClick.page),
                  ),
                  RadioRow(
                    key: const ValueKey('scroll click spot'),
                    label: l.appearanceScrollSpot,
                    selected: services.scrollClick.value == ScrollClick.spot,
                    onSelected: () => services.setScrollClick(ScrollClick.spot),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The mode previews under a heading, with the note below (kit `Mode Light`, `Mode Dark`,
/// `Mode Automatic`: cards 76 × 88, 24 apart).
class _ModeSection extends StatelessWidget {
  const _ModeSection({required this.children, required this.note});
  final List<Widget> children;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(l.appearanceMode),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: children,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(note, style: AmalfiType.caption(color: colors.disabled)),
        ),
      ],
    );
  }
}

/// The colour dot before a pop-up's value (the highlight and folder colours).
class _Swatch extends StatelessWidget {
  const _Swatch({this.color, this.gradient = false});
  final Color? color;
  final bool gradient;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      gradient: gradient
          ? const LinearGradient(colors: [Color(0xFF8E9BF0), Color(0xFFF7A9A0)])
          : null,
    ),
  );
}

/// A preview of a mode (72 × 48, the chosen one inside a 3 pt accent ring) with its label
/// under it, bold when chosen (ST-APP-01).
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
    Widget half(bool dark) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF2B1F6B), Color(0xFF0E1236)]
              : const [Color(0xFFB9D3F2), Color(0xFF6F98D8)],
        ),
      ),
      child: Stack(
        children: [
          // A window with an accent title bar and, in front, another with its buttons.
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: 40,
              height: 14,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF26262A) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(3),
              ),
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 42,
              height: 22,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1B1C1F) : const Color(0xFFFFFFFF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.only(left: 7, top: 8),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Dot(Color(0xFFEC6A5E)),
                  _Dot(Color(0xFFF4BF4F)),
                  _Dot(Color(0xFF61C554)),
                ],
              ),
            ),
          ),
        ],
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
                width: 72 + 6,
                height: 48 + 6,
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
                        Expanded(
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxWidth: 72,
                              child: half(false),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerRight,
                              maxWidth: 72,
                              child: half(true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  },
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: settingsText(
                  11,
                  selected ? colors.text : colors.secondary,
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

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.only(right: 3),
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

/// The nine accent swatches: 24 pt, 36 pt apart (ST-APP-02); the chosen one inside a ring
/// of its colour, with its name under it.
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

  static const Gradient _multicolour = SweepGradient(
    colors: [
      Color(0xFFF0562E),
      Color(0xFFFFCC00),
      Color(0xFF34A853),
      Color(0xFF0E77E6),
      Color(0xFFAF52DE),
      Color(0xFFF0562E),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final dark = colors.dark;
    final chosen = Accent.values.indexOf(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, accent) in Accent.values.indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Semantics(
                button: true,
                selected: accent == value,
                label: name(l, accent),
                child: GestureDetector(
                  key: ValueKey('accent ${accent.name}'),
                  onTap: () => onChanged(accent),
                  child: Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: accent == value
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.plain(dark: dark),
                              width: 2,
                            ),
                          )
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: accent == Accent.multicolour
                            ? _multicolour
                            : null,
                        color: accent == Accent.multicolour
                            ? null
                            : accent.plain(dark: dark),
                        border: accent == value
                            ? Border.all(
                                color: const Color(0xFFFFFFFF),
                                width: 1,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        // The chosen accent's name hangs under its swatch, centred on it.
        SizedBox(
          width: Accent.values.length * 36 - 12,
          height: 17,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: chosen * 36 - 28,
                top: 3,
                width: 80,
                child: Text(
                  name(l, value),
                  key: const ValueKey('accent name'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: settingsText(11, colors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
