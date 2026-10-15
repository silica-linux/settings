// The Settings window (ST-NAV-01): the sidebar on the left, the content on the right under a
// 52 pt toolbar with the back / forward capsule at x 269 and the title of the current pane.
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

  /// Panes that open with a header card leave the toolbar title out until the card scrolls
  /// away (ST-NAV-01: the card already names the pane).
  final ValueNotifier<bool> _scrolledPastHeader = ValueNotifier(false);
  Location? _shownLocation;

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
    _scrolledPastHeader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = widget.navigation;
    final colors = SettingsColors.of(context);
    if (_shownLocation != navigation.location) {
      _shownLocation = navigation.location;
      _scrolledPastHeader.value = false;
    }
    final header = hasHeaderCard(navigation.location);
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: SettingsMetrics.sidebarWidth,
                  child: SettingsSidebar(
                    navigation: navigation,
                    groups: groups,
                    searchFocus: _searchFocus,
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: colors.content,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _scrolledPastHeader,
                          builder: (context, scrolled, _) => _Toolbar(
                            navigation: navigation,
                            showTitle: !header || scrolled,
                          ),
                        ),
                        Expanded(
                          child: NotificationListener<ScrollUpdateNotification>(
                            onNotification: (n) {
                              if (header && n.metrics.axis == Axis.vertical) {
                                _scrolledPastHeader.value =
                                    n.metrics.pixels > headerCardScroll;
                              }
                              return false;
                            },
                            child: KeyedSubtree(
                              key: ValueKey(navigation.location),
                              child: paneBody(
                                context,
                                navigation.location,
                                open: navigation.openSub,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// How far a header card scrolls before the toolbar shows the title (provisional: about
/// the card's height).
const double headerCardScroll = 120;

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.navigation, required this.showTitle});
  final Navigation navigation;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    return SizedBox(
      height: toolbarHeight,
      child: WindowDragArea(
        child: Row(
          children: [
            const SizedBox(
              width: SettingsMetrics.navX - SettingsMetrics.sidebarWidth,
            ),
            ToolbarCapsule(
              separators: true,
              children: [
                ToolbarSegment(
                  key: const ValueKey('back'),
                  width: SettingsMetrics.navSegment,
                  enabled: navigation.canGoBack,
                  onTap: navigation.back,
                  icon: (color) => CustomPaint(
                    size: const Size(7, 12),
                    painter: ChevronPainter(ChevronDirection.left, color),
                  ),
                ),
                ToolbarSegment(
                  key: const ValueKey('forward'),
                  width: SettingsMetrics.navSegment,
                  enabled: navigation.canGoForward,
                  onTap: navigation.forward,
                  icon: (color) => CustomPaint(
                    size: const Size(7, 12),
                    painter: ChevronPainter(ChevronDirection.right, color),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                showTitle ? locationTitle(l, navigation.location) : '',
                key: const ValueKey('title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: settingsText(15, colors.text, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
