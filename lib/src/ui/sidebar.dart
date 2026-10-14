// The sidebar (ST-NAV-02, ST-NAV-03): the search field at the top, the account cell under it,
// then the panes in blocks with their coloured icons; the selected row is an accent capsule
// with white text (gray in an inactive window). Typing replaces the list with two-line
// results (setting, then the path to it); Esc clears the query and brings the panes back.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/navigation.dart';
import '../model/panes.dart';
import '../model/titles.dart';
import '../services.dart';
import '../style.dart';
import 'symbol.dart';

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

  @override
  void dispose() {
    _query.dispose();
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
          Center(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _clear,
              },
              child: SizedBox(
                width: SettingsMetrics.searchWidth,
                height: SettingsMetrics.searchHeight,
                child: SilicaSearchField(
                  key: const ValueKey('sidebar search'),
                  labels: SearchFieldLabels(
                    placeholder: l.searchPlaceholder,
                    clear: l.searchClear,
                  ),
                  controller: _query,
                  focusNode: widget.searchFocus,
                  width: SettingsMetrics.searchWidth,
                  onChanged: (text) => navigation.query = text,
                  onCancel: _clear,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!searching) ...[
            _AccountCell(
              onTap: () => navigation.openPane(PaneId.users),
              selected: navigation.pane == PaneId.users,
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: searching
                ? _Results(navigation: navigation, groups: widget.groups)
                : _PaneList(navigation: navigation, groups: widget.groups),
          ),
        ],
      ),
    );
  }
}

/// The local user: initials, full name, "Local account"; opens Users & Groups.
class _AccountCell extends StatelessWidget {
  const _AccountCell({required this.onTap, required this.selected});
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    final name = info.userName.isEmpty ? l.accountLocalUser : info.userName;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: SettingsMetrics.rowInset),
        child: GestureDetector(
          key: const ValueKey('account cell'),
          onTap: onTap,
          child: SizedBox(
            width: SettingsMetrics.accountWidth,
            height: SettingsMetrics.accountHeight,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8E8E93),
                  ),
                  child: Text(
                    initials,
                    style: settingsText(
                      12,
                      const Color(0xFFFFFFFF),
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: settingsText(
                          13,
                          colors.text,
                          weight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                      Text(
                        l.accountLocal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: settingsText(11, colors.secondary),
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
    final accent = ControlAccent.of(context);
    final fill = selected ? (active ? accent : colors.inactiveSelection) : null;
    final textColor = selected && active
        ? const Color(0xFFFFFFFF)
        : colors.text;
    final secondaryColor = selected && active
        ? const Color(0xCCFFFFFF)
        : colors.secondary;
    final two = subtitle != null;
    return SizedBox(
      height: two ? 44 : SettingsMetrics.rowPitch,
      child: Center(
        child: Semantics(
          button: true,
          selected: selected,
          label: title,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The selection moves on release (ST-NAV-05: ~40–80 ms after the mouse up).
            onTap: onTap,
            child: Container(
              height: two ? 40 : SettingsMetrics.rowHeight,
              margin: const EdgeInsets.symmetric(
                horizontal: SettingsMetrics.rowInset,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(two ? 8 : 12),
              ),
              child: Row(
                children: [
                  IconTile(symbol: pane.symbol, tint: pane.tint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _highlighted(
                          title,
                          settingsText(13, textColor),
                          highlight,
                        ),
                        if (subtitle case final subtitle?)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: settingsText(11, secondaryColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
