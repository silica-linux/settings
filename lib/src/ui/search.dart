// The sidebar search field (kit `Search`: Fields/Search Field/Regular, 240 × 28 at (10, 60)).
// Esc clears the query (ST-NAV-03); the clear button is the field's own.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../style.dart';

class SidebarSearchField extends StatelessWidget {
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
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
    child: AmalfiSearchField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      clearLabel: clearLabel,
      width: SettingsMetrics.searchWidth,
      onChanged: onChanged,
      onCleared: onCancel,
      semanticLabel: placeholder,
    ),
  );
}
