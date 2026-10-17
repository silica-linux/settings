// The sidebar (ST-NAV-02, ST-NAV-03): the search field at the top, the account cell under it,
// then the panes in blocks with their coloured icons; the selected row is a soft accent capsule
// as tall as the row pitch with semibold text (gray in an inactive window). Typing
// replaces the list with two-line results (setting, then the path to it); Esc clears the
// query and brings the panes back. The sidebar icon size of Appearance scales the rows.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../accent.dart';
import '../model/navigation.dart';
import '../model/panes.dart';
import '../model/titles.dart';
import '../services.dart';
import '../style.dart';
import 'search.dart';
import 'symbol.dart';

/// The row geometry for each sidebar icon size (Appearance › sidebar icon size). Medium is
/// measured (ST-NAV-02); small and large are provisional.
@immutable
class SidebarRowSize {
  const SidebarRowSize(this.pitch, this.icon, this.text);
  final double pitch;
  final double icon;
  final double text;

  static SidebarRowSize of(SidebarIconSize size) => switch (size) {
    SidebarIconSize.small => const SidebarRowSize(28, 20, 13),
    SidebarIconSize.medium => const SidebarRowSize(
      SettingsMetrics.rowPitch,
      SettingsMetrics.iconSize,
      14,
    ),
    SidebarIconSize.large => const SidebarRowSize(40, 28, 15),
  };
}

class SettingsSidebar extends StatefulWidget {
  const SettingsSidebar({
    super.key,
    required this.navigation,
    required this.groups,
    this.searchFocus,
  });

  final Navigation navigation;
  final List<List<PaneId>> groups;
  final FocusNode? searchFocus;

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  final TextEditingController _query = TextEditingController();
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.searchFocus ?? (_ownFocus ??= FocusNode(debugLabel: 'search'));

  @override
  void dispose() {
    _query.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _clear() {
    _query.clear();
    widget.navigation.query = '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final l = AppLocalizations.of(context);
    final navigation = widget.navigation;
    final searching = navigation.query.trim().isNotEmpty;
    // The accent and the icon size change the rows (Appearance).
    return ListenableBuilder(
      listenable: ServicesScope.of(context).look,
      builder: (context, _) =>
          _build(context, colors, l, navigation, searching),
    );
  }

  Widget _build(
    BuildContext context,
    SettingsColors colors,
    AppLocalizations l,
    Navigation navigation,
    bool searching,
  ) {
    return ColoredBox(
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The band of the window buttons (drawn by Ossido) is the window's drag area.
          const SizedBox(
            height: SettingsMetrics.searchTop,
            child: WindowDragArea(child: SizedBox.expand()),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: SettingsMetrics.searchLeft),
              child: SidebarSearchField(
                key: const ValueKey('sidebar search'),
                controller: _query,
                focusNode: _focus,
                placeholder: l.searchPlaceholder,
                clearLabel: l.searchClear,
                onChanged: (text) => navigation.query = text,
                onCancel: _clear,
              ),
            ),
          ),
          if (searching) ...[
            const SizedBox(height: 10),
            Expanded(
              child: _Results(navigation: navigation, groups: widget.groups),
            ),
          ] else ...[
            const SizedBox(
              height:
                  SettingsMetrics.accountTop -
                  SettingsMetrics.searchTop -
                  SettingsMetrics.searchHeight,
            ),
            _AccountCell(onTap: () => navigation.openPane(PaneId.users)),
            const SizedBox(
              height:
                  SettingsMetrics.paneListTop -
                  SettingsMetrics.accountTop -
                  SettingsMetrics.accountHeight,
            ),
            Expanded(
              child: _PaneList(navigation: navigation, groups: widget.groups),
            ),
          ],
        ],
      ),
    );
  }
}

/// The local user: the person glyph on a soft accent disc, full name, "Local account"; opens
/// Users & Groups (kit `Account avatar`, `Account name`, `Account kind`).
class _AccountCell extends StatelessWidget {
  const _AccountCell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmalfiTheme.of(context).colors;
    final l = AppLocalizations.of(context);
    final info = HostInfoScope.of(context);
    final name = info.userName.isEmpty ? l.accountLocalUser : info.userName;
    return Semantics(
      button: true,
      label: name,
      child: GestureDetector(
        key: const ValueKey('account cell'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: SettingsMetrics.accountHeight,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              children: [
                Container(
                  width: SettingsMetrics.accountAvatar,
                  height: SettingsMetrics.accountAvatar,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentAmalfiSoft,
                  ),
                  child: SettingsSymbol(
                    'person',
                    color: colors.accentAmalfi,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmalfiType.headline(color: colors.textPrimary),
                      ),
                      Text(
                        l.accountLocal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmalfiType.callout(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaneList extends StatelessWidget {
  const _PaneList({required this.navigation, required this.groups});
  final Navigation navigation;
  final List<List<PaneId>> groups;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final (i, group) in groups.indexed) ...[
          if (i > 0) const SizedBox(height: SettingsMetrics.groupGap),
          for (final pane in group)
            _SidebarRow(
              key: ValueKey('pane ${pane.name}'),
              title: paneTitle(l, pane),
              pane: pane,
              selected: navigation.pane == pane,
              onTap: () => navigation.openPane(pane),
            ),
        ],
      ],
    );
  }
}

/// The soft selection fill: the accent's soft tint (the theme's with the default accent, the
/// accent's fill at 16 % with another one), gray in an inactive window.
Color sidebarSelection(BuildContext context, {required bool active}) {
  final colors = SettingsColors.of(context);
  if (!active) return colors.inactiveSelection;
  final accent = ServicesScope.of(context).accent.value;
  return accent == Accent.multicolour || accent == Accent.blue
      ? AmalfiTheme.of(context).colors.accentAmalfiSoft
      : accent.fill(dark: colors.dark).withValues(alpha: 0.16);
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    super.key,
    required this.title,
    required this.pane,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.highlight,
  });

  final String title;
  final String? subtitle;
  final PaneId pane;
  final bool selected;
  final VoidCallback onTap;

  /// The query to emphasise in the title (search results).
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final active = WindowActiveScope.of(context);
    final size = SidebarRowSize.of(
      ServicesScope.of(context).sidebarIconSize.value,
    );
    final fill = selected ? sidebarSelection(context, active: active) : null;
    final textColor = colors.text;
    final secondaryColor = colors.secondary;
    final two = subtitle != null;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The selection moves on release (ST-NAV-05: ~40–80 ms after the mouse up).
        onTap: onTap,
        child: Container(
          height: two ? 44 : size.pitch,
          margin: const EdgeInsets.symmetric(
            horizontal: SettingsMetrics.rowInset,
          ),
          padding: const EdgeInsets.only(
            left: SettingsMetrics.rowIconLeft,
            right: 8,
          ),
          decoration: ShapeDecoration(
            color: fill,
            shape: AmalfiSmoothBorder(radius: SettingsMetrics.selectionRadius),
          ),
          child: Row(
            children: [
              IconTile(symbol: pane.symbol, tint: pane.tint, size: size.icon),
              const SizedBox(width: SettingsMetrics.rowIconGap),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlighted(
                      title,
                      settingsText(
                        size.text,
                        textColor,
                        weight: selected ? FontWeight.w600 : null,
                      ),
                      highlight,
                    ),
                    if (subtitle case final subtitle?)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmalfiType.callout(color: secondaryColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The title with the matched characters in semibold. How the reference marks them is
  /// unmeasured (ST-NAV-03): provisional.
  static Widget _highlighted(String text, TextStyle style, String? query) {
    final q = query?.trim().toLowerCase() ?? '';
    final at = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (at < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: text.substring(at, at + q.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(at + q.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.navigation, required this.groups});
  final Navigation navigation;
  final List<List<PaneId>> groups;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final index = searchIndex(l, groups.expand((g) => g));
    final results = searchMatches(index, navigation.query);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l.searchNoResults,
          key: const ValueKey('no results'),
          textAlign: TextAlign.center,
          style: settingsText(13, colors.secondary),
        ),
      );
    }
    return ListView(
      children: [
        for (final entry in results)
          _SidebarRow(
            key: ValueKey('result ${entry.title} ${entry.location}'),
            title: entry.title,
            subtitle: entry.path(l),
            pane: entry.location.pane,
            highlight: navigation.query,
            selected: navigation.location == entry.location,
            onTap: () => navigation.open(entry.location),
          ),
      ],
    );
  }
}
