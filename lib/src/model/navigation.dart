// Where the Settings window is and how it got there: the selected pane or sub-pane, the
// back / forward history of the toolbar and the sidebar search query. A switch replaces the
// content in one frame with no transition (ST-NAV-05).

import 'package:flutter/foundation.dart';

import 'panes.dart';

class Navigation extends ChangeNotifier {
  Navigation({Location initial = const Location(PaneId.appearance)})
    : _history = [initial];

  final List<Location> _history;
  int _index = 0;
  String _query = '';

  Location get location => _history[_index];
  PaneId get pane => location.pane;
  bool get canGoBack => _index > 0;
  bool get canGoForward => _index < _history.length - 1;

  /// The sidebar search text; empty shows the pane list.
  String get query => _query;

  /// Goes to [to]; going to the current place changes nothing (no history entry).
  void open(Location to) {
    if (to == location) return;
    _history
      ..removeRange(_index + 1, _history.length)
      ..add(to);
    _index = _history.length - 1;
    notifyListeners();
  }

  void openPane(PaneId pane) => open(Location(pane));

  void openSub(SubPaneId sub, [String detail = '']) =>
      open(Location(pane, sub, detail));

  void back() {
    if (!canGoBack) return;
    _index--;
    notifyListeners();
  }

  void forward() {
    if (!canGoForward) return;
    _index++;
    notifyListeners();
  }

  set query(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }
}
