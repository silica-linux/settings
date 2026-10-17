// The measured geometry and colours of the Settings window (docs/spec/window.md, ST-NAV-01..04).
// Values without a measurement are marked provisional.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

abstract final class SettingsMetrics {
  /// The window: 832 wide, fixed; 780 tall by default (kit `Apps/Settings/<pane>`).
  static const double windowWidth = 832;
  static const double windowHeight = 780;

  /// The shortest window that still shows the toolbar and a few rows (provisional).
  static const double minHeight = 400;

  /// Sidebar width 240, its trailing 1 pt separator inside it at x 239: the content starts at
  /// x 240, the standard Amalfi sidebar of Mustache and Mail (components.md, readability pass).
  static const double sidebarWidth = 240;

  /// The search field: 216 × 28 at (12, 60), the standard sidebar padding on both sides.
  static const double searchWidth = 216;
  static const double searchHeight = 28;
  static const double searchTop = 60;
  static const double searchLeft = AmalfiSidebarMetrics.padding;

  /// The account cell: avatar 36 at (12, 100), name at x 60 (kit `Account avatar`).
  static const double accountTop = 100;
  static const double accountHeight = 36;
  static const double accountAvatar = 36;

  /// The first pane row starts 156 below the window's top (kit `Sidebar list`).
  static const double paneListTop = 156;

  /// Sidebar rows: 32 tall on a pitch of 32, the soft selection capsule 12 from both edges (216 wide, silica_ui's sidebar metrics),
  /// radius 8; the 24 pt tile at x 10 of the sidebar (glyph 16, y 4 in the row), the label at
  /// x 44. Blocks are 12 apart on top of the pitch.
  static const double rowPitch = AmalfiSidebarMetrics.rowHeight;
  static const double rowInset = AmalfiSidebarMetrics.padding;
  static const double selectionRadius = AmalfiSidebarMetrics.radius;
  static const double rowIconLeft = 10;
  static const double rowIconGap = 10;
  static const double groupGap = 12;

  /// The icon tile of a sidebar row: 24, radius 6 (glyph 16).
  static const double iconSize = 24;
  static const double iconRadius = 6;

  /// The back / forward capsule: two 36 pt segments (the Nav piece) at x 248, 8 after the
  /// sidebar's divider.
  static const double navX = 248;
  static const double navSegment = 36;

  /// Grouped lists (kit `Apps/Settings/Row/*`): inset 20 from the content's sides, 12 between
  /// groups; navigation rows 52, value rows 40, text rows 52, check rows 36.
  static const double listInset = 20;
  static const double pageTop = 16;
  static const double navRowHeight = 52;
  static const double valueRowHeight = 44;
  static const double checkRowHeight = 48;
  static const double groupSpacing = 12;
  static const double headingAbove = 11;
  static const double headingBelow = 11;

  /// Group corners: radius 12 (kit `Group`).
  static const double groupRadius = 12;

  /// Row text starts 12 from the group's edge; separators are inset 12 on both sides;
  /// controls end 12 from the trailing edge.
  static const double rowTextInset = 12;
  static const double trailingInset = 12;
  static const double separatorInset = 12;

  /// Navigation rows: a 24 pt tile (radius 6) 12 from the edge, the title at x 48.
  static const double navIconSize = 24;
  static const double navIconLeft = 12;
  static const double navIconGap = 12;

  /// Section headings: Body Emphasis 13.
  static const double headingSize = 13;
}

/// The colours of the window in one appearance, from the Amalfi tokens.
@immutable
class SettingsColors {
  const SettingsColors({
    required this.dark,
    required this.sidebar,
    required this.content,
    required this.group,
    required this.separator,
    required this.text,
    required this.secondary,
    required this.disabled,
    required this.selection,
    required this.badge,
    required this.inactiveSelection,
  });

  final bool dark;

  /// `Surface/Sidebar`.
  final Color sidebar;

  /// `Surface/Window`.
  final Color content;

  /// The group fill: `Surface/Sidebar` (kit `Group`).
  final Color group;

  /// `Line/Separator`.
  final Color separator;
  final Color text;

  /// `Text/Secondary`.
  final Color secondary;

  /// `Text/Tertiary`.
  final Color disabled;

  /// `Accent/Amalfi`, the default sidebar selection.
  final Color selection;

  /// `Surface/Control`, the chevron badge.
  final Color badge;

  /// The selected row of an inactive window: `Line/Separator`.
  final Color inactiveSelection;

  static SettingsColors forBrightness(Brightness brightness) {
    final c = AmalfiColors.of(brightness);
    return SettingsColors(
      dark: brightness == Brightness.dark,
      sidebar: c.surfaceSidebar,
      content: c.surfaceWindow,
      group: c.surfaceSidebar,
      separator: c.lineSeparator,
      text: c.textPrimary,
      secondary: c.textSecondary,
      disabled: c.textTertiary,
      selection: c.accentAmalfi,
      badge: c.surfaceControl,
      inactiveSelection: c.lineSeparator,
    );
  }

  static final light = forBrightness(Brightness.light);
  static final darkColors = forBrightness(Brightness.dark);

  static SettingsColors of(BuildContext context) =>
      AmalfiTheme.of(context).isDark ? darkColors : light;
}

TextStyle settingsText(
  double size,
  Color color, {
  FontWeight? weight,
  double? height,
}) => TextStyle(
  fontFamily: uiFontFamily,
  package: 'silica_ui',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);
