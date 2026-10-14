// Menu Bar (ST-CCT-01), Displays (ST-DSP-01..03), Desktop and Dock (ST-DSK-01..04) and
// Wallpaper (ST-WLP-01/02). Real today: the displays as Flutter sees them (read-only), the
// Dock's magnification and recent-apps options (dock.json, read by the shell's Dock) and the
// wallpaper (wallpaper.json, read by the shell's wallpaper layer). The shell reads both files
// when it starts: the footers say so. Everything else has no backend yet.

import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../services.dart';
import '../style.dart';
import '../ui/grouped.dart';

class MenuBarPane extends StatelessWidget {
  const MenuBarPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          children: [
            PopUpRow<int>(
              title: l.menuBarAutoHide,
              items: [PopUpItem(0, l.menuBarNever)],
              value: 0,
            ),
            SwitchRow(title: l.menuBarBackground, value: true),
            ValueRow(
              title: l.menuBarRecentItems,
              trailing: const SilicaStepper(value: 10, onChanged: null),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.menuBarControls,
          unavailable: true,
          children: [
            for (final title in [
              l.paneWifi,
              l.paneBluetooth,
              l.paneSound,
              l.paneFocus,
            ])
              PopUpRow<int>(
                title: title,
                items: [PopUpItem(0, l.menuBarShowWhenActive)],
                value: 0,
              ),
          ],
        ),
      ],
    );
  }
}

class DisplaysPane extends StatelessWidget {
  const DisplaysPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final displays = PlatformDispatcher.instance.displays.toList();
    return PanePage(
      children: [
        for (final (i, d) in displays.indexed)
          SettingsGroup(
            heading: displays.length > 1 ? l.aboutDisplayN(i + 1) : null,
            footer: l.displaysReadOnly,
            children: [
              ValueRow(
                key: ValueKey('display $i resolution'),
                title: l.displaysResolution,
                trailing: Text(
                  '${d.size.width.round()} × ${d.size.height.round()}',
                  style: settingsText(13, SettingsColors.of(context).secondary),
                ),
              ),
              ValueRow(
                title: l.displaysScale,
                trailing: Text(
                  '${d.devicePixelRatio.toStringAsFixed(d.devicePixelRatio == d.devicePixelRatio.roundToDouble() ? 0 : 2)}×',
                  style: settingsText(13, SettingsColors.of(context).secondary),
                ),
              ),
              ValueRow(
                title: l.displaysRefreshRate,
                trailing: Text(
                  d.refreshRate > 0 ? '${d.refreshRate.round()} Hz' : '—',
                  style: settingsText(13, SettingsColors.of(context).secondary),
                ),
              ),
            ],
          ),
        if (displays.isEmpty)
          SettingsGroup(children: [ValueRow(title: l.aboutUnknown)]),
        SettingsGroup(
          unavailable: true,
          children: [
            PopUpRow<int>(
              title: l.displaysColorProfile,
              items: [PopUpItem(0, l.appearanceDefaultChoice)],
              value: 0,
            ),
            PopUpRow<int>(
              title: l.displaysRotation,
              items: [PopUpItem(0, l.displaysStandard)],
              value: 0,
            ),
            ButtonRow(
              title: l.displaysNightLight,
              label: l.displaysNightLightButton,
            ),
          ],
        ),
      ],
    );
  }
}

class DesktopDockPane extends StatefulWidget {
  const DesktopDockPane({super.key});

  @override
  State<DesktopDockPane> createState() => _DesktopDockPaneState();
}

class _DesktopDockPaneState extends State<DesktopDockPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    // The shell's defaults (shell/lib/dock/dock.dart): magnification on, recents off.
    final magnify = config.flag('dock', 'magnify', fallback: true);
    final recents = config.flag('dock', 'recents', fallback: false);
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.dockSection,
          footer: l.dockRestartNote,
          children: [
            SwitchRow(
              key: const ValueKey('dock magnify'),
              title: l.dockMagnification,
              value: magnify,
              onChanged: (on) =>
                  setState(() => config.write('dock', 'magnify', on)),
            ),
            SwitchRow(
              key: const ValueKey('dock recents'),
              title: l.dockRecents,
              value: recents,
              onChanged: (on) =>
                  setState(() => config.write('dock', 'recents', on)),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            SliderRow(title: l.dockSize, value: 0.3839),
            PopUpRow<int>(
              title: l.dockPosition,
              items: [PopUpItem(0, l.dockBottom)],
              value: 0,
            ),
            PopUpRow<int>(
              title: l.dockMinimizeEffect,
              items: [PopUpItem(0, l.dockGenie)],
              value: 0,
            ),
            PopUpRow<int>(
              title: l.dockDoubleClick,
              items: [PopUpItem(0, l.dockZoom)],
              value: 0,
            ),
            SwitchRow(title: l.dockMinimizeIntoIcon, value: false),
            SwitchRow(title: l.dockAutoHide, value: false),
            SwitchRow(title: l.dockAnimate, value: true),
            SwitchRow(title: l.dockIndicators, value: true),
          ],
        ),
        SettingsGroup(
          heading: l.desktopSection,
          unavailable: true,
          children: [
            PopUpRow<int>(
              title: l.desktopClickWallpaper,
              items: [PopUpItem(0, l.desktopOnlyInStage)],
              value: 0,
            ),
            SwitchRow(title: l.desktopStage, value: false),
          ],
        ),
        SettingsGroup(
          heading: l.panoramaSection,
          unavailable: true,
          children: [
            SwitchRow(title: l.panoramaRearrange, value: true),
            SwitchRow(title: l.panoramaSwitchToApp, value: true),
            SwitchRow(title: l.panoramaGroupByApp, value: false),
            SwitchRow(title: l.panoramaSeparateSpaces, value: true),
          ],
        ),
        ButtonBar(
          buttons: [
            SilicaButton(label: l.dockShortcutsButton, onPressed: null),
            SilicaButton(
              key: const ValueKey('hot corners'),
              label: l.dockHotCorners,
              onPressed: () => showHotCorners(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// The hot corners sheet (ST-DSK-04): 711 × 193, four 269 × 24 pop-ups around a 100 × 69
/// desktop preview, Done. Ossido has no hot corners yet: the pop-ups are shown, not active.
Future<void> showHotCorners(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showWindowSheet<void>(
    context,
    semanticLabel: l.dockHotCorners,
    builder: (context, sheet) {
      final colors = SettingsColors.of(context);
      Widget corner() => IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: 269,
            height: 24,
            child: PopUpButton<int>(
              items: [PopUpItem(0, l.hotCornerNone)],
              value: 0,
              onChanged: null,
              width: 269,
            ),
          ),
        ),
      );
      return SizedBox(
        width: 711,
        height: 193,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [corner(), corner()],
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 69,
                          decoration: BoxDecoration(
                            color: colors.group,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.separator),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [corner(), corner()],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.notAvailableYet,
                      style: settingsText(11, colors.secondary),
                    ),
                  ),
                  SilicaButton(
                    key: const ValueKey('hot corners done'),
                    label: l.done,
                    role: ButtonRole.primary,
                    onPressed: sheet.close,
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

/// A wallpaper choice as written in wallpaper.json.
sealed class WallpaperOption {
  const WallpaperOption();
  Map<String, Object?> get json;
}

class DefaultWallpaper extends WallpaperOption {
  const DefaultWallpaper();
  @override
  Map<String, Object?> get json => const {};
}

class ColorWallpaper extends WallpaperOption {
  const ColorWallpaper(this.color);
  final Color color;

  String get hex =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Map<String, Object?> get json => {'color': hex};
}

class ImageWallpaper extends WallpaperOption {
  const ImageWallpaper(this.path);
  final String path;
  @override
  Map<String, Object?> get json => {'image': path};
}

/// The current choice, as the shell reads it.
WallpaperOption readWallpaper(Map<String, Object?> json) {
  if (json['image'] case final String path) return ImageWallpaper(path);
  if (json['color'] case final String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value != null && hex.replaceFirst('#', '').length == 6) {
      return ColorWallpaper(Color(0xFF000000 | value));
    }
  }
  return const DefaultWallpaper();
}

/// The solid colours (one category is plain colours; the reference sessions used `#7a7b80`;
/// the others are ours).
const List<Color> wallpaperColors = [
  Color(0xFF7A7B80),
  Color(0xFF1F2A44),
  Color(0xFF2E5E4E),
  Color(0xFF6B3A5B),
  Color(0xFFB86F4A),
  Color(0xFF101012),
];

class WallpaperPane extends StatefulWidget {
  const WallpaperPane({super.key});

  @override
  State<WallpaperPane> createState() => _WallpaperPaneState();
}

class _WallpaperPaneState extends State<WallpaperPane> {
  List<String>? _pictures;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pictures ??= _findPictures(ServicesScope.of(context).env);
  }

  /// Images in the user's pictures folder (first level, at most 24).
  static List<String> _findPictures(Map<String, String> env) {
    final dirs = xdgUserDirs(env);
    final pictures = dirs['PICTURES'] ?? '${env['HOME'] ?? ''}/Pictures';
    try {
      final dir = Directory(pictures);
      if (!dir.existsSync()) return const [];
      final files = [
        for (final e in dir.listSync())
          if (e is File &&
              RegExp(
                r'\.(png|jpe?g|webp)$',
                caseSensitive: false,
              ).hasMatch(e.path))
            e.path,
      ]..sort();
      return files.take(24).toList();
    } on FileSystemException {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    final current = readWallpaper(config.read('wallpaper'));
    void choose(WallpaperOption option) =>
        setState(() => config.replace('wallpaper', option.json));
    final pictures = _pictures ?? const [];
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.wallpaperRestartNote,
          children: [
            ValueRow(
              title: _name(l, current),
              height: 116,
              leading: _Thumb(option: current, width: 160, height: 100),
              trailing: IgnorePointer(
                child: Opacity(
                  opacity: 0.5,
                  child: PopUpButton<int>(
                    items: [PopUpItem(0, l.wallpaperFill)],
                    value: 0,
                    onChanged: null,
                  ),
                ),
              ),
            ),
          ],
        ),
        _Category(
          title: l.wallpaperSilica,
          options: const [DefaultWallpaper()],
          current: current,
          onChoose: choose,
        ),
        _Category(
          title: l.wallpaperColors,
          options: [for (final c in wallpaperColors) ColorWallpaper(c)],
          current: current,
          onChoose: choose,
        ),
        if (pictures.isNotEmpty)
          _Category(
            title: l.wallpaperPictures,
            options: [for (final p in pictures) ImageWallpaper(p)],
            current: current,
            onChoose: choose,
          ),
        ButtonBar(
          buttons: [
            SilicaButton(label: l.wallpaperScreenSaver, onPressed: null),
          ],
        ),
      ],
    );
  }

  static String _name(AppLocalizations l, WallpaperOption o) => switch (o) {
    DefaultWallpaper() => l.wallpaperSilicaName,
    ColorWallpaper(:final hex) => hex,
    ImageWallpaper(:final path) => path.split('/').last,
  };
}

class _Category extends StatelessWidget {
  const _Category({
    required this.title,
    required this.options,
    required this.current,
    required this.onChoose,
  });

  final String title;
  final List<WallpaperOption> options;
  final WallpaperOption current;
  final ValueChanged<WallpaperOption> onChoose;

  bool _same(WallpaperOption a, WallpaperOption b) => switch ((a, b)) {
    (DefaultWallpaper(), DefaultWallpaper()) => true,
    (ColorWallpaper(:final hex), final ColorWallpaper other) =>
      hex == other.hex,
    (ImageWallpaper(:final path), final ImageWallpaper other) =>
      path == other.path,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SettingsMetrics.rowTextInset,
            4,
            0,
            6,
          ),
          child: Text(
            title,
            style: settingsText(13, colors.text, weight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 101,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    key: ValueKey('wallpaper ${option.json}'),
                    onTap: () => onChoose(option),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          width: 3,
                          color: _same(option, current)
                              ? accent
                              : const Color(0x00000000),
                        ),
                      ),
                      child: _Thumb(option: option, width: 109, height: 83),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.option,
    required this.width,
    required this.height,
  });

  final WallpaperOption option;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      width: width,
      height: height,
      child: switch (option) {
        // The default is drawn by the shell (twilight over dunes); a gradient stands for it.
        DefaultWallpaper() => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2A55), Color(0xFFD8A08A), Color(0xFF4A2B44)],
            ),
          ),
        ),
        ColorWallpaper(:final color) => ColoredBox(color: color),
        ImageWallpaper(:final path) => Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: (width * 2).round(),
          errorBuilder: (context, error, stack) =>
              const ColoredBox(color: Color(0xFF7A7B80)),
        ),
      },
    ),
  );
}
