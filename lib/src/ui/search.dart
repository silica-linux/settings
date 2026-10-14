// The sidebar search field (ST-NAV-02/03): a 242 × 28 capsule with the toolbar capsule's
// outline (light top and bottom edges, darker sides) over a light fill, a 14 pt magnifier, the
// placeholder, and a clear button while there is text; the 3 pt accent ring with the keyboard
// focus. Colours sampled from the reference: fill `#e9e9ea` / `#5c5c5d`. silica_ui's search
// field has the 38 pt toolbar capsule and the filled 28 pt inline field, not this one.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../style.dart';

class SidebarSearchField extends StatefulWidget {
  const SidebarSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.clearLabel,
    required this.onChanged,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  @override
  State<SidebarSearchField> createState() => _SidebarSearchFieldState();
}

class _SidebarSearchFieldState extends State<SidebarSearchField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = SettingsColors.of(context).dark;
    final glyph = dark ? const Color(0xFFB4B4B7) : const Color(0xFF7E7E83);
    final hasText = widget.controller.text.isNotEmpty;
    return Semantics(
      textField: true,
      label: widget.placeholder,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: SizedBox(
          width: SettingsMetrics.searchWidth,
          height: SettingsMetrics.searchHeight,
          child: FocusRing(
            visible: widget.focusNode.hasFocus,
            radius: SettingsMetrics.searchHeight / 2,
            // The ring's stack loosens the size: the capsule fills it again.
            child: SizedBox(
              width: SettingsMetrics.searchWidth,
              height: SettingsMetrics.searchHeight,
              child: CustomPaint(
                painter: ToolbarFieldPainter(
                  fill: dark
                      ? const Color(0xFF5C5C5D)
                      : const Color(0xFFE9E9EA),
                  top: dark ? const Color(0xFF7F7F82) : const Color(0xFFFFFFFF),
                  side: dark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFB4B4B6),
                  bottom: dark
                      ? const Color(0xFF6E6E70)
                      : const Color(0xFFFFFFFF),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 14,
                        child: CustomPaint(painter: MagnifierGlyph(glyph)),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.escape):
                                widget.onCancel,
                          },
                          child: InputEditable(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            placeholder: widget.placeholder,
                            onChanged: widget.onChanged,
                          ),
                        ),
                      ),
                      if (hasText)
                        Semantics(
                          button: true,
                          label: widget.clearLabel,
                          child: GestureDetector(
                            key: const ValueKey('searchClear'),
                            onTap: widget.onCancel,
                            child: SizedBox.square(
                              dimension: 14,
                              child: CustomPaint(painter: ClearGlyph(glyph)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
