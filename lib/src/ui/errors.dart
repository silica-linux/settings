// What a refused change says (a [ToolError] from the system tools).

import '../../l10n/gen/app_localizations.dart';
import '../system/tools.dart';

String errorText(AppLocalizations l, ToolError error) => switch (error.kind) {
  ToolErrorKind.missing => l.errorMissing,
  ToolErrorKind.authentication => l.errorAuthentication,
  ToolErrorKind.refused => l.errorRefused(_short(error.detail)),
  ToolErrorKind.failed => l.errorFailed(_short(error.detail)),
};

/// The last line of a tool's message, without the program's name.
String _short(String detail) {
  final lines = detail
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (lines.isEmpty) return '';
  var line = lines.last;
  final colon = line.indexOf(': ');
  if (colon > 0 && colon < 24 && !line.substring(0, colon).contains(' ')) {
    line = line.substring(colon + 2);
  }
  return line.length > 160 ? '${line.substring(0, 160)}…' : line;
}
