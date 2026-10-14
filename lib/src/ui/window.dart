// The Settings window (ST-NAV-01): the sidebar on the left, the content on the right under a
// 52 pt toolbar with the back / forward capsule at x 269 and the title of the current pane.
// Switching panes replaces the content in one frame, with no transition (ST-NAV-05).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/navigation.dart';
import '../model/panes.dart';
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
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = widget.navigation;
    final colors = SettingsColors.of(context);
    return SystemStateBuilder(
      builder: (context, state) {
        final groups = paneGroups(hasBattery: state.batteryPresent);
        // A pane that left the sidebar (Energy and Battery swap) falls back to the first.
        final shown = groups.expand((g) => g).toSet();
        if (!shown.contains(navigation.pane)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => navigation.openPane(shown.first),
          );
        }
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
                navigation.back,
            const SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
                navigation.forward,
            const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                _searchFocus.requestFocus,
          },
          child: Focus(
            autofocus: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: SettingsMetrics.sidebarWidth - 1,
                  child: SettingsSidebar(
                    navigation: navigation,
                    groups: groups,
                    searchFocus: _searchFocus,
                  ),
                ),
                Container(width: 1, color: colors.divider),
                Expanded(
                  child: ColoredBox(
                    color: colors.content,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Toolbar(navigation: navigation),
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey(navigation.location),
                            child: paneBody(
                              context,
                              navigation.location,
                              open: navigation.openSub,
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

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.navigation});
  final Navigation navigation;

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
                locationTitle(l, navigation.location),
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
