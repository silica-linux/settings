// The pop-up of the settings forms (ST-NAV-04): no bezel, the chosen value in the text colour
// and a 20 pt round badge with the up/down chevrons at the trailing edge, 12 from the group's
// edge. A press opens the menu with the chosen item over the value; Space, Return and the
// arrows open it from the keyboard. silica_ui's PopUpButton is the bezelled capsule of
// windows and dialogs; this form style is not in silica_ui yet.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../style.dart';

/// The chevron badge: 20 pt (ST-NAV-04).
const double popUpBadge = 20;

class FormPopUp<T> extends StatefulWidget {
  const FormPopUp({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.leading,
    this.placeholder = '',
  });

  final List<PopUpItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  /// Drawn before the value (the highlight colour's swatch).
  final Widget? leading;

  /// Shown when no item has [value].
  final String placeholder;

  @override
  State<FormPopUp<T>> createState() => _FormPopUpState<T>();
}

class _FormPopUpState<T> extends State<FormPopUp<T>> {
  OverlayEntry? _menu;
  final FocusNode _focus = FocusNode(debugLabel: 'form pop-up');

  @override
  void dispose() {
    _menu?.remove();
    _menu = null;
    _focus.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null && widget.items.isNotEmpty;

  void _open() {
    if (!_enabled || _menu != null) return;
    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject();
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null ||
        box is! RenderBox ||
        overlayBox is! RenderBox ||
        !box.hasSize) {
      return;
    }
    final onChanged = widget.onChanged!;
    final entries = <MenuEntry>[
      for (final item in widget.items)
        MenuAction(
          item.label,
          checked: item.value == widget.value,
          enabled: item.enabled,
          onSelected: () => onChanged(item.value),
        ),
    ];
    final size = menuSize(entries);
    final tops = menuRowTops(entries);
    final chosen = widget.items.indexWhere((i) => i.value == widget.value);
    final origin = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
    // The chosen item's text over the value's text; the menu ends at the badge.
    var at = Offset(
      origin.dx + box.size.width - size.width + 4,
      origin.dy +
          box.size.height / 2 -
          tops[chosen < 0 ? 0 : chosen] -
          MenuMetrics.itemHeight / 2,
    );
    at = Offset(
      at.dx.clamp(
        0,
        (overlayBox.size.width - size.width).clamp(0, double.infinity),
      ),
      at.dy.clamp(
        0,
        (overlayBox.size.height - size.height).clamp(0, double.infinity),
      ),
    );
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: MenuHost(
          entries: entries,
          anchor: at,
          opaque: true,
          onDismissed: _close,
        ),
      ),
    );
    _menu = entry;
    overlay.insert(entry);
    setState(() {});
  }

  void _close() {
    _menu?.remove();
    _menu = null;
    if (mounted) setState(() {});
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      _open();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final chosen = widget.items.where((i) => i.value == widget.value);
    final text = chosen.isEmpty ? widget.placeholder : chosen.first.label;
    final enabled = _enabled;
    final textColor = enabled ? colors.text : colors.disabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: text,
      child: Focus(
        focusNode: _focus,
        canRequestFocus: enabled,
        onKeyEvent: _key,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _open() : null,
          child: Padding(
            // The badge sits 12 from the group's edge, rows end 10 from it.
            padding: const EdgeInsets.only(right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading case final leading?) ...[
                  leading,
                  const SizedBox(width: 8),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: settingsText(13, textColor),
                  ),
                ),
                const SizedBox(width: 11),
                Container(
                  key: const ValueKey('pop-up badge'),
                  width: popUpBadge,
                  height: popUpBadge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _menu != null
                        ? Color.lerp(colors.badge, colors.text, 0.12)
                        : colors.badge,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(6, 3.5),
                        painter: ChevronPainter(
                          ChevronDirection.up,
                          textColor,
                          stroke: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomPaint(
                        size: const Size(6, 3.5),
                        painter: ChevronPainter(
                          ChevronDirection.down,
                          textColor,
                          stroke: 1.3,
                        ),
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

/// Opens [entries] as a menu under the widget of [context] (its trailing edges aligned);
/// [onClosed] runs when it goes. Returns false without an overlay.
bool showMenuUnder(
  BuildContext context,
  List<MenuEntry> entries, {
  VoidCallback? onClosed,
}) {
  final overlay = Overlay.maybeOf(context);
  final box = context.findRenderObject();
  final overlayBox = overlay?.context.findRenderObject();
  if (overlay == null ||
      box is! RenderBox ||
      overlayBox is! RenderBox ||
      !box.hasSize) {
    return false;
  }
  final size = menuSize(entries);
  final origin = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
  final at = Offset(
    (origin.dx + box.size.width - size.width).clamp(
      0,
      (overlayBox.size.width - size.width).clamp(0, double.infinity),
    ),
    (origin.dy + box.size.height + 4).clamp(
      0,
      (overlayBox.size.height - size.height).clamp(0, double.infinity),
    ),
  );
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: MenuHost(
        entries: entries,
        anchor: at,
        opaque: true,
        onDismissed: () {
          entry.remove();
          onClosed?.call();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return true;
}

/// The round "…" button at the end of a row (a network, a device): its menu holds the row's
/// actions.
class MoreButton extends StatelessWidget {
  const MoreButton({
    super.key,
    required this.entries,
    required this.semanticLabel,
  });

  /// Built when the menu opens, so it shows the current state.
  final List<MenuEntry> Function() entries;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showMenuUnder(context, entries()),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.secondary, width: 1.2),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 2.2,
                    height: 2.2,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.secondary,
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

/// Asks to confirm a destructive action with silica_ui's alert, centred over the window;
/// true when [confirm] was chosen. Esc and Cancel answer false.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
}) {
  final overlay = Overlay.of(context);
  final done = Completer<bool>();
  late final OverlayEntry entry;
  void answer(bool value) {
    if (done.isCompleted) return;
    entry.remove();
    done.complete(value);
  }

  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: ColoredBox(
        color: const Color(0x33000000),
        child: Center(
          child: SilicaAlert(
            key: const ValueKey('confirm'),
            title: title,
            message: message,
            opaque: true,
            sideBySide: true,
            buttons: [
              AlertButton(
                cancel,
                role: AlertRole.cancel,
                onPressed: () => answer(false),
              ),
              AlertButton(
                confirm,
                role: AlertRole.destructive,
                onPressed: () => answer(true),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}
