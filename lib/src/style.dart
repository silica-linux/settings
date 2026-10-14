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

  /// Sidebar width, divider at x 261 (ST-NAV-02).
  static const double sidebarWidth = 261;

  /// The search field: 241 × 28 at the top of the sidebar (its top is provisional).
  static const double searchWidth = 241;
  static const double searchHeight = 28;
  static const double searchTop = toolbarHeight;

  /// The account cell under the search field: 168 × 38 (its gap is provisional).
  static const double accountWidth = 168;
  static const double accountHeight = 38;

  /// Sidebar rows: pitch 32, the row button 24 tall; ~13 pt extra between blocks.
  static const double rowPitch = 32;
  static const double rowHeight = 24;
  static const double groupGap = 13;

  /// Sidebar row insides (provisional): the capsule 10 from the sidebar edges, the icon
  /// square 20 with radius 5, the label after it.
  static const double rowInset = 10;
  static const double iconSize = 20;
  static const double iconRadius = 5;

  /// The back / forward capsule: two 36 pt segments at x 269 (ST-NAV-01).
  static const double navX = 269;
  static const double navSegment = 36;

  /// Grouped lists (ST-NAV-04): inset 20 from the content edges, navigation rows 48 (pitch
  /// 49 with the separator), value rows 36–44 (40 here), ~10 between groups.
  static const double listInset = 20;
  static const double navRowHeight = 48;
  static const double valueRowHeight = 40;
  static const double groupSpacing = 10;

  /// Group corners: rounded, radius unmeasured (provisional).
  static const double groupRadius = 10;

  /// The trailing inset of switches and other trailing controls (16, ST-NAV-04).
  static const double trailingInset = 16;

  /// The leading inset of row text (provisional: the separator starts at the text).
  static const double rowTextInset = 14;

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
    required this.divider,
    required this.inactiveSelection,
  });

  final bool dark;

  /// Sidebar material, ≈ `#e3e4e6` / `#323335` (translucent on the reference; solid here until
  /// the window can ask Ossido for glass behind the sidebar).
  final Color sidebar;

  /// Content background `#ffffff` / `#272728`.
  final Color content;

  /// Group fill `#f7f7f7` / `#2d2d2e`.
  final Color group;

  /// Row separator `#efefef` / `#424243`.
  final Color separator;
  final Color text;

  /// Secondary text (provisional grays).
  final Color secondary;
  final Color disabled;

  /// The 1 pt line between the sidebar and the content (provisional).
  final Color divider;

  /// The selected row of an inactive window (provisional, the list gray of the file manager).
  final Color inactiveSelection;

  static const light = SettingsColors(
    dark: false,
    sidebar: Color(0xFFE3E4E6),
    content: Color(0xFFFFFFFF),
    group: Color(0xFFF7F7F7),
    separator: Color(0xFFEFEFEF),
    text: Color(0xFF1D1D1F),
    secondary: Color(0xFF808080),
    disabled: Color(0xFFB0B0B0),
    divider: Color(0xFFD6D6D6),
    inactiveSelection: Color(0xFFDCDCDC),
  );

  static const darkColors = SettingsColors(
    dark: true,
    sidebar: Color(0xFF323335),
    content: Color(0xFF272728),
    group: Color(0xFF2D2D2E),
    separator: Color(0xFF424243),
    text: Color(0xFFE5E5E7),
    secondary: Color(0xFF9A9A9E),
    disabled: Color(0xFF6A6A6D),
    divider: Color(0xFF1C1C1D),
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
