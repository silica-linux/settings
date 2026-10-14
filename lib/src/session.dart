// Where Settings opens: the pane named on the command line, else the one the window was last
// on (`settings.json` in Silica's configuration folder, key `lastPane`), else Appearance.

import 'model/navigation.dart';
import 'model/panes.dart';
import 'system/config.dart';

const String sessionFile = 'settings';
const String lastPaneKey = 'lastPane';

PaneId? _named(String name) {
  for (final pane in PaneId.values) {
    if (pane.name.toLowerCase() == name.toLowerCase()) return pane;
  }
  return null;
}

/// The first argument names a pane (`--dart-arg wifi` on the embedder).
PaneId initialPane(List<String> args, ConfigStore config) {
  final fromArgs = args.isEmpty ? null : _named(args.first);
  if (fromArgs != null) return fromArgs;
  final remembered = config.text(sessionFile, lastPaneKey, fallback: '');
  return _named(remembered) ?? PaneId.appearance;
}

/// Saves the pane every time the window goes to another one.
void rememberPane(Navigation navigation, ConfigStore config) {
  var last = navigation.pane;
  navigation.addListener(() {
    if (navigation.pane == last) return;
    last = navigation.pane;
    config.write(sessionFile, lastPaneKey, last.name);
  });
}
