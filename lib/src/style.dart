// The measured geometry and colours of the Settings window (docs/spec/window.md, ST-NAV-01..04).
// Values without a measurement are marked provisional.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

abstract final class SettingsMetrics {
  /// The window: 832 wide, fixed; 727 tall by default (ST-NAV-01).
  static const double windowWidth = 832;
  static const double windowHeight = 727;

  /// The shortest window that still shows the toolbar and a few rows (provisional).
  static const double minHeight = 400;

  /// Sidebar width: the content starts at x 261, with no line between them (ST-NAV-02).
  static const double sidebarWidth = 261;

  /// The search field: 242 × 28, 9 from the sidebar's left edge, its top 60 below the
  /// window's (ST-NAV-02).
  static const double searchWidth = 242;
  static const double searchHeight = 28;
  static const double searchTop = 60;
  static const double searchLeft = 9;

  /// The account cell under the search field: top at 98, 44 tall (ST-NAV-02).
  static const double accountTop = 98;
  static const double accountHeight = 44;

  /// The first pane row starts 157 below the window's top (ST-NAV-02).
  static const double paneListTop = 157;

  /// Sidebar rows: pitch 32, the selection capsule as tall as the pitch, radius 8, 10 from
  /// both sidebar edges; the icon 20 pt at x 19, the label 7 after it (ST-NAV-02).
  static const double rowPitch = 32;
  static const double rowInset = 10;
  static const double selectionRadius = 8;
  static const double rowIconLeft = 9;
  static const double rowIconGap = 7;
  static const double groupGap = 13;

  /// The icon square of a sidebar row: 20, radius 5 (radius provisional).
  static const double iconSize = 20;
  static const double iconRadius = 5;

  /// The back / forward capsule: two 36 pt segments at x 269 (ST-NAV-01).
  static const double navX = 269;
  static const double navSegment = 36;

  /// Grouped lists (ST-NAV-04): inset 20 from the content's sides and 12 under the toolbar;
  /// navigation rows 48 (pitch 49), value rows 37 (pitch 38), 10 between groups; a heading
  /// leaves 32 above its text (22 more than a group gap) and 10 below.
  static const double listInset = 20;
  static const double pageTop = 12;
  static const double navRowHeight = 48;
  static const double valueRowHeight = 37;
  static const double groupSpacing = 10;
  static const double headingAbove = 22;
  static const double headingBelow = 10;

  /// Group corners: radius 10 (ST-NAV-04, from the corner's antialiasing).
  static const double groupRadius = 10;

  /// Row text starts 10 from the group's edge; separators are inset 10 on both sides;
  /// switches end 10 from the trailing edge, pop-up chevron badges 12 (ST-NAV-04).
  static const double rowTextInset = 10;
  static const double trailingInset = 10;
  static const double separatorInset = 10;

  /// Navigation rows: a 24 pt icon square 12 from the edge, the title 12 after it (ST-NAV-04).
  static const double navIconSize = 24;
  static const double navIconLeft = 12;
  static const double navIconGap = 12;

  /// Section headings: bold 13 above their group.
  static const double headingSize = 13;
}

/// The colours of the window in one appearance.
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

  /// Sidebar material: `#ececec` / `#2a2a2b` as measured over the reference desktop
  /// (translucent there; solid here until the window can ask Ossido for glass behind it).
  final Color sidebar;

  /// Content background `#ffffff` / `#272728`.
  final Color content;

  /// Group fill `#f7f7f7` / `#2d2d2e`.
  final Color group;

  /// Row separator `#ebebeb` / `#373738` (ST-NAV-04).
  final Color separator;
  final Color text;

  /// Secondary text (provisional grays).
  final Color secondary;
  final Color disabled;

  /// The sidebar selection with the default accent: `#2565f1` / `#296ffb` (ST-NAV-02).
  final Color selection;

  /// The chevron badge of a form pop-up: a 20 pt circle (provisional shade).
  final Color badge;

  /// The selected row of an inactive window (provisional, the list gray of the file manager).
  final Color inactiveSelection;

  static const light = SettingsColors(
    dark: false,
    sidebar: Color(0xFFECECEC),
    content: Color(0xFFFFFFFF),
    group: Color(0xFFF7F7F7),
    separator: Color(0xFFEBEBEB),
    text: Color(0xFF1D1D1F),
    secondary: Color(0xFF808080),
    disabled: Color(0xFFB0B0B0),
    selection: Color(0xFF2565F1),
    badge: Color(0xFFE6E6E6),
    inactiveSelection: Color(0xFFDCDCDC),
  );

  static const darkColors = SettingsColors(
    dark: true,
    sidebar: Color(0xFF2A2A2B),
    content: Color(0xFF272728),
    group: Color(0xFF2D2D2E),
    separator: Color(0xFF373738),
    text: Color(0xFFE5E5E7),
    secondary: Color(0xFF9A9A9E),
    disabled: Color(0xFF6A6A6D),
    selection: Color(0xFF296FFB),
    badge: Color(0xFF424243),
    inactiveSelection: Color(0xFF464646),
  );

  static SettingsColors of(BuildContext context) =>
      MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
      ? darkColors
      : light;
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
