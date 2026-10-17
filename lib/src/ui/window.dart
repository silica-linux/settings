// The Settings window (kit `Apps/Settings/*`): the 240 pt sidebar on the left, no divider
// (the tone step Surface/Sidebar to Surface/Window), the content on the right under a 52 pt toolbar with the back / forward
// capsule at x 248 and the title of the current pane after it.
// Switching panes replaces the content in one frame, with no transition (ST-NAV-05).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/navigation.dart';
import '../model/panes.dart';
import '../menus.dart';
import '../model/titles.dart';
import '../panes/panes.dart';
import '../services.dart';
import '../style.dart';
import 'sidebar.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({super.key, required this.navigation});

  final Navigation navigation;

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  final FocusNode _searchFocus = FocusNode(debugLabel: 'sidebar search');

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_focusChanged);
  }

  // The text items of Edit follow the search field's focus.
  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _searchFocus.removeListener(_focusChanged);
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = widget.navigation;
    final colors = SettingsColors.of(context);
    return SystemStateBuilder(
      builder: (context, state) {
        final groups = paneGroups(
          hasBattery: state.batteryPresent,
          hasTrackpad: state.touchpad,
        );
        // A pane that left the sidebar (Energy and Battery swap) falls back to the first.
        final shown = groups.expand((g) => g).toSet();
        // The Trackpad is known only once the daemon has answered: the window reopened on it
        // waits for the first state instead of falling back.
        final waiting = navigation.pane == PaneId.trackpad && !state.reachable;
        if (!shown.contains(navigation.pane) && !waiting) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => navigation.openPane(shown.first),
          );
        }
        // The menus bind the shortcuts: back and forward (⌘[ ⌘]), search (⌘F), the text items.
        return SilicaMenuBar(
          menus: settingsMenus(
            AppLocalizations.of(context),
            navigation: navigation,
            panes: shown.toList(),
            focusSearch: _searchFocus.requestFocus,
            searchFocused: _searchFocus.hasFocus,
            hasText: navigation.query.isNotEmpty,
          ),
          child: Focus(
            autofocus: true,
            child: ColoredBox(
              color: colors.content,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The content starts at x 240; the group inset is measured from there.
                  Positioned(
                    left: SettingsMetrics.sidebarWidth,
                    right: 0,
                    top: toolbarHeight,
                    bottom: 0,
                    child: KeyedSubtree(
                      key: ValueKey(navigation.location),
                      child: paneBody(
                        context,
                        navigation.location,
                        open: navigation.openSub,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: SettingsMetrics.sidebarWidth,
                    child: SettingsSidebar(
                      navigation: navigation,
                      groups: groups,
                      searchFocus: _searchFocus,
                    ),
                  ),
                  Positioned(
                    left: SettingsMetrics.sidebarWidth,
                    right: 0,
                    top: 0,
                    height: toolbarHeight,
                    child: ColoredBox(color: colors.content),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: toolbarHeight,
                    child: _Toolbar(navigation: navigation),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.navigation});
  final Navigation navigation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = AmalfiTheme.of(context).colors;
    final active = WindowActiveScope.of(context);
    // The bar is transparent over the sidebar (the window buttons, drawn by Ossido, sit on
    // its surface): the nav capsule at x 248, the title after it (kit `Back and forward`,
    // `Title`).
    return WindowDragArea(
      child: AmalfiToolbar(
        surface: AmalfiToolbarSurface.none,
        children: [
          const SizedBox(width: SettingsMetrics.navX - 4),
          AmalfiToolbarPiece(
            child: AmalfiActionSegments(
              key: const ValueKey('nav'),
              segments: [
                AmalfiSegment.icon(
                  const AmalfiGlyph(AmalfiGlyphs.chevronLeft),
                  semanticLabel: l.menuBack,
                  enabled: navigation.canGoBack,
                ),
                AmalfiSegment.icon(
                  const AmalfiGlyph(AmalfiGlyphs.chevronRight),
                  semanticLabel: l.menuForward,
                  enabled: navigation.canGoForward,
                ),
              ],
              onPressed: (i) =>
                  i == 0 ? navigation.back() : navigation.forward(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  locationTitle(l, navigation.location),
                  key: const ValueKey('title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmalfiType.headline(
                    color: active ? colors.textPrimary : colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
