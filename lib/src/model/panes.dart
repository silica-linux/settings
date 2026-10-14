// The panes of the sidebar, in the measured order (docs/spec/panes.md, ST-NAV-02). The grouping
// into blocks separated by ~13 pt is measured; which pane closes each block is not, and
// follows the order of topics (network, system, attention, security, accounts, input):
// provisional. The reference's panes for its own online services (assistant, game service,
// cloud account, payments) have no counterpart in Silica and are left out.

import 'dart:ui' show Color;

/// A pane of the sidebar.
enum PaneId {
  wifi('wifi', Color(0xFF0A84FF)),
  bluetooth('bluetooth', Color(0xFF0A84FF)),
  network('globe', Color(0xFF0A84FF)),
  vpn('network', Color(0xFF0A84FF)),
  energy('bolt-fill', Color(0xFFFFB800)),
  battery('battery', Color(0xFF34C759)),
  general('gear', Color(0xFF8E8E93)),
  accessibility('accessibility', Color(0xFF0A84FF)),
  appearance('appearance', Color(0xFF1C1C1E)),
  menuBar('menubar', Color(0xFF1C1C1E)),
  displays('display', Color(0xFF0A84FF)),
  desktopDock('dock', Color(0xFF1C1C1E)),
  wallpaper('photo', Color(0xFF32ADE6)),
  search('search', Color(0xFF8E8E93)),
  notifications('bell-badge', Color(0xFFFF3B30)),
  sound('speaker', Color(0xFFFF2D55)),
  focus('moon', Color(0xFF5E5CE6)),
  screenTime('hourglass', Color(0xFF5E5CE6)),
  lockScreen('lock', Color(0xFF1C1C1E)),
  privacy('shield', Color(0xFF0A84FF)),
  password('key', Color(0xFFFF3B30)),
  users('person-2', Color(0xFF0A84FF)),
  internetAccounts('at', Color(0xFF0A84FF)),
  keyboard('keyboard', Color(0xFF8E8E93)),
  mouse('mouse', Color(0xFF8E8E93)),
  printers('printer', Color(0xFF8E8E93));

  const PaneId(this.symbol, this.tint);

  /// The silica-icons symbol (`symbols/regular/<symbol>.svg`), white on [tint].
  final String symbol;

  /// The fill of the rounded square behind the symbol (provisional colours: the reference's
  /// are coloured squares, not measured one by one).
  final Color tint;
}

/// The sidebar blocks, top to bottom. [hasBattery] swaps Energy for Battery, as on a
/// machine with a battery.
List<List<PaneId>> paneGroups({required bool hasBattery}) => [
  [
    PaneId.wifi,
    PaneId.bluetooth,
    PaneId.network,
    PaneId.vpn,
    hasBattery ? PaneId.battery : PaneId.energy,
  ],
  [
    PaneId.general,
    PaneId.accessibility,
    PaneId.appearance,
    PaneId.menuBar,
    PaneId.displays,
    PaneId.desktopDock,
    PaneId.wallpaper,
    PaneId.search,
  ],
  [PaneId.notifications, PaneId.sound, PaneId.focus, PaneId.screenTime],
  [PaneId.lockScreen, PaneId.privacy, PaneId.password, PaneId.users],
  [PaneId.internetAccounts],
  [PaneId.keyboard, PaneId.mouse, PaneId.printers],
];

/// The sub-panes that have their own page (pushed inside a pane, with Back).
enum SubPaneId {
  about,
  softwareUpdate,
  storage,
  sharing,
  dateTime,
  startupDisk,
  loginItems,
  languageRegion,
  backups,
  transferReset,
}

/// Where the window is: a pane, optionally one of its sub-panes.
class Location {
  const Location(this.pane, [this.sub]);
  final PaneId pane;
  final SubPaneId? sub;

  @override
  bool operator ==(Object other) =>
      other is Location && other.pane == pane && other.sub == sub;

  @override
  int get hashCode => Object.hash(pane, sub);

  @override
  String toString() => sub == null ? pane.name : '${pane.name}/${sub!.name}';
}
