// The content of each place of the window.

import 'package:flutter/widgets.dart';

import '../model/panes.dart';
import 'appearance.dart';
import 'attention.dart';
import 'desktop.dart';
import 'focus.dart';
import 'general.dart';
import 'input.dart';
import 'network.dart';
import 'power.dart';
import 'security.dart';

/// The page for [at]; [open] pushes a sub-pane of the current pane.
Widget paneBody(
  BuildContext context,
  Location at, {
  required void Function(SubPaneId sub, [String detail]) open,
}) {
  if (at.sub == SubPaneId.notificationApp) {
    return NotificationAppPane(detail: at.detail);
  }
  if (at.sub case final sub?) return generalSubPane(sub);
  return switch (at.pane) {
    PaneId.wifi => const WifiPane(),
    PaneId.bluetooth => const BluetoothPane(),
    PaneId.network => const NetworkPane(),
    PaneId.vpn => const VpnPane(),
    PaneId.energy => const EnergyPane(),
    PaneId.battery => const BatteryPane(),
    PaneId.general => GeneralPane(open: open),
    PaneId.accessibility => const AccessibilityPane(),
    PaneId.appearance => const AppearancePane(),
    PaneId.menuBar => const MenuBarPane(),
    PaneId.displays => const DisplaysPane(),
    PaneId.desktopDock => const DesktopDockPane(),
    PaneId.wallpaper => const WallpaperPane(),
    PaneId.search => const SearchPane(),
    PaneId.notifications => NotificationsPane(open: open),
    PaneId.sound => const SoundPane(),
    PaneId.focus => const FocusPane(),
    PaneId.screenTime => const ScreenTimePane(),
    PaneId.lockScreen => const LockScreenPane(),
    PaneId.privacy => const PrivacyPane(),
    PaneId.password => const PasswordPane(),
    PaneId.users => const UsersPane(),
    PaneId.internetAccounts => const InternetAccountsPane(),
    PaneId.keyboard => const KeyboardPane(),
    PaneId.mouse => const MousePane(),
    PaneId.trackpad => const TrackpadPane(),
    PaneId.printers => const PrintersPane(),
  };
}
