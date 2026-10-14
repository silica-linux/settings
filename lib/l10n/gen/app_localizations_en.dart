// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Settings';

  @override
  String get notAvailableYet => 'Not available yet in Silica.';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit…';

  @override
  String get empty => 'Empty';

  @override
  String get on => 'On';

  @override
  String get searchPlaceholder => 'Search';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchNoResults => 'No results';

  @override
  String get accountLocal => 'Local account';

  @override
  String get accountLocalUser => 'User';

  @override
  String get paneWifi => 'Wi-Fi';

  @override
  String get paneBluetooth => 'Bluetooth';

  @override
  String get paneNetwork => 'Network';

  @override
  String get paneVpn => 'VPN';

  @override
  String get paneEnergy => 'Energy';

  @override
  String get paneBattery => 'Battery';

  @override
  String get paneGeneral => 'General';

  @override
  String get paneAccessibility => 'Accessibility';

  @override
  String get paneAppearance => 'Appearance';

  @override
  String get paneMenuBar => 'Menu Bar';

  @override
  String get paneDisplays => 'Displays';

  @override
  String get paneDesktopDock => 'Desktop & Dock';

  @override
  String get paneWallpaper => 'Wallpaper';

  @override
  String get paneSearch => 'Search';

  @override
  String get paneNotifications => 'Notifications';

  @override
  String get paneSound => 'Sound';

  @override
  String get paneFocus => 'Focus';

  @override
  String get paneScreenTime => 'Screen Time';

  @override
  String get paneLockScreen => 'Lock Screen';

  @override
  String get panePrivacy => 'Privacy & Security';

  @override
  String get panePassword => 'Login Password';

  @override
  String get paneUsers => 'Users & Groups';

  @override
  String get paneInternetAccounts => 'Internet Accounts';

  @override
  String get paneKeyboard => 'Keyboard';

  @override
  String get paneMouse => 'Mouse';

  @override
  String get panePrinters => 'Printers & Scanners';

  @override
  String get subAbout => 'About';

  @override
  String get subSoftwareUpdate => 'Software Update';

  @override
  String get subStorage => 'Storage';

  @override
  String get subSharing => 'Sharing';

  @override
  String get subDateTime => 'Date & Time';

  @override
  String get subStartupDisk => 'Startup Disk';

  @override
  String get subLoginItems => 'Login Items';

  @override
  String get subLanguageRegion => 'Language & Region';

  @override
  String get subBackups => 'Backups';

  @override
  String get subTransferReset => 'Transfer or Reset';

  @override
  String get wifiNoDevice => 'No Wi-Fi device found';

  @override
  String get wifiConnected => 'Connected';

  @override
  String get wifiKnownNetworks => 'Known Networks';

  @override
  String get wifiOtherNetworks => 'Other Networks';

  @override
  String get wifiConnect => 'Connect';

  @override
  String get wifiSearching => 'Looking for networks…';

  @override
  String get wifiNoOtherNetworks => 'No other networks';

  @override
  String get wifiNewNetworkUnavailable =>
      'Joining a new network needs its password, which Silica can\'t ask for yet. Saved networks can be joined.';

  @override
  String get wifiAskToJoin => 'Ask to join networks';

  @override
  String get wifiAskToJoinHotspots => 'Ask to join hotspots';

  @override
  String get wifiAskNotify => 'Notify';

  @override
  String get wifiAskNever => 'Never';

  @override
  String get bluetoothNoAdapter => 'No Bluetooth adapter found';

  @override
  String get bluetoothMyDevices => 'My Devices';

  @override
  String get bluetoothNoDevices => 'No paired devices';

  @override
  String get bluetoothConnected => 'Connected';

  @override
  String get bluetoothNotConnected => 'Not connected';

  @override
  String get bluetoothConnect => 'Connect';

  @override
  String get bluetoothDisconnect => 'Disconnect';

  @override
  String get bluetoothNearby => 'Nearby Devices';

  @override
  String get bluetoothNearbyNone => 'Searching for new devices';

  @override
  String get networkWired => 'Ethernet';

  @override
  String get networkConnected => 'Connected';

  @override
  String get networkNotConnected => 'Not connected';

  @override
  String get networkOff => 'Off';

  @override
  String get networkFirewall => 'Firewall';

  @override
  String get vpnNone => 'No VPN configurations';

  @override
  String get vpnAdd => 'Add VPN Configuration…';

  @override
  String get energyPreventSleep =>
      'Keep the computer awake when the display is off';

  @override
  String get energyWakeForNetwork => 'Wake for network access';

  @override
  String get energyRestartAfterPowerFailure =>
      'Start up again after a power failure';

  @override
  String get batteryLevel => 'Battery level';

  @override
  String get batteryCharging => 'Charging';

  @override
  String get batteryOnBattery => 'On battery';

  @override
  String get batteryLowPowerMode => 'Low power mode';

  @override
  String get batteryOptimizedCharging => 'Optimised charging';

  @override
  String get generalDescription =>
      'Manage this computer: its software, storage, sharing, date, language and more.';

  @override
  String get aboutThisComputer => 'This computer';

  @override
  String get aboutName => 'Name';

  @override
  String get aboutProcessor => 'Processor';

  @override
  String get aboutMemory => 'Memory';

  @override
  String get aboutSystem => 'System';

  @override
  String get aboutKernel => 'Kernel';

  @override
  String get aboutDisplays => 'Displays';

  @override
  String get aboutUnknown => 'Unknown';

  @override
  String get storageCalculating => 'Calculating…';

  @override
  String get storageSystemDisk => 'System disk';

  @override
  String get storageRecommendations => 'Recommendations';

  @override
  String get storageEmptyTrash => 'Empty the Trash automatically';

  @override
  String get sharingFiles => 'File sharing';

  @override
  String get sharingScreen => 'Screen sharing';

  @override
  String get sharingRemoteLogin => 'Remote login';

  @override
  String get sharingComputerName => 'Computer name';

  @override
  String get sharingNameReadOnly =>
      'The name can\'t be changed from Settings yet.';

  @override
  String get dateTimeZone => 'Time zone';

  @override
  String get dateTimeAutomatic => 'Set time and date automatically';

  @override
  String get dateTime24Hour => '24-hour time';

  @override
  String get languagePreferred => 'Preferred language';

  @override
  String get languageReadOnly =>
      'The system language can\'t be changed from Settings yet.';

  @override
  String get languageRegion => 'Region';

  @override
  String get languageFirstDay => 'First day of the week';

  @override
  String get languageMonday => 'Monday';

  @override
  String get updateInstalled => 'Installed system';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateCheckButton => 'Check Now';

  @override
  String get updateAutomatic => 'Install updates automatically';

  @override
  String get accessibilityDescription =>
      'Make the computer easier to see, hear and control, in the way that suits you.';

  @override
  String get accessibilityVision => 'Vision';

  @override
  String get accessibilityPhysical => 'Motor';

  @override
  String get accessibilityHearing => 'Hearing';

  @override
  String get accessibilityScreenReader => 'Screen reader';

  @override
  String get accessibilityZoom => 'Zoom';

  @override
  String get accessibilityLargerText => 'Larger text';

  @override
  String get accessibilityDisplay => 'Display';

  @override
  String get accessibilityMotion => 'Motion';

  @override
  String get accessibilitySpokenContent => 'Spoken content';

  @override
  String get accessibilityVoiceControl => 'Voice control';

  @override
  String get accessibilityPointer => 'Pointer control';

  @override
  String get accessibilityAudio => 'Audio';

  @override
  String get accessibilityCaptions => 'Captions';

  @override
  String get appearanceMode => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceAuto => 'Automatic';

  @override
  String get appearanceNoDaemon =>
      'The system service isn\'t running: this can\'t be changed now.';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceAccent => 'Accent colour';

  @override
  String get appearanceHighlight => 'Highlight colour';

  @override
  String get appearanceIconStyle => 'Icon and widget style';

  @override
  String get appearanceFolderColor => 'Folder colour';

  @override
  String get appearanceGlass => 'Glass';

  @override
  String get appearanceAutomaticChoice => 'Automatic';

  @override
  String get appearanceDefaultChoice => 'Default';

  @override
  String get appearanceWindows => 'Windows';

  @override
  String get appearanceSidebarIconSize => 'Sidebar icon size';

  @override
  String get appearanceMedium => 'Medium';

  @override
  String get appearanceTint => 'Tint windows with the wallpaper colour';

  @override
  String get appearanceScrollBars => 'Show scroll bars';

  @override
  String get appearanceScrollAuto => 'Automatically';

  @override
  String get appearanceScrollClick => 'Click in the scroll bar to';

  @override
  String get appearanceScrollNextPage => 'Jump to the next page';

  @override
  String get accentMulticolour => 'Multicolour';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentRed => 'Red';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentYellow => 'Yellow';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentGraphite => 'Graphite';

  @override
  String get menuBarAutoHide => 'Hide the menu bar automatically';

  @override
  String get menuBarNever => 'Never';

  @override
  String get menuBarBackground => 'Show the menu bar background';

  @override
  String get menuBarRecentItems => 'Recent items';

  @override
  String get menuBarControls => 'Menu bar controls';

  @override
  String get menuBarShowWhenActive => 'Show when active';

  @override
  String get displaysResolution => 'Resolution';

  @override
  String get displaysScale => 'Scale';

  @override
  String get displaysRefreshRate => 'Refresh rate';

  @override
  String get displaysReadOnly =>
      'Silica can\'t change the display mode from Settings yet.';

  @override
  String get displaysColorProfile => 'Colour profile';

  @override
  String get displaysRotation => 'Rotation';

  @override
  String get displaysStandard => 'Standard';

  @override
  String get displaysNightLight => 'Night light';

  @override
  String get displaysNightLightButton => 'Night Light…';

  @override
  String get dockSection => 'Dock';

  @override
  String get dockMagnification => 'Magnification';

  @override
  String get dockRecents => 'Show suggested and recent apps';

  @override
  String get dockRestartNote =>
      'The Dock reads these choices when the session starts.';

  @override
  String get dockSize => 'Size';

  @override
  String get dockPosition => 'Position on screen';

  @override
  String get dockBottom => 'Bottom';

  @override
  String get dockMinimizeEffect => 'Minimise windows using';

  @override
  String get dockGenie => 'Genie effect';

  @override
  String get dockDoubleClick => 'Double-click a title bar to';

  @override
  String get dockZoom => 'Zoom';

  @override
  String get dockMinimizeIntoIcon => 'Minimise windows into the app icon';

  @override
  String get dockAutoHide => 'Hide and show the Dock automatically';

  @override
  String get dockAnimate => 'Animate opening apps';

  @override
  String get dockIndicators => 'Show indicators for open apps';

  @override
  String get dockShortcutsButton => 'Shortcuts…';

  @override
  String get dockHotCorners => 'Hot Corners…';

  @override
  String get desktopSection => 'Desktop';

  @override
  String get desktopClickWallpaper => 'Click the wallpaper to show the desktop';

  @override
  String get desktopOnlyInStage => 'Only in stage view';

  @override
  String get desktopStage => 'Stage view';

  @override
  String get panoramaSection => 'Panorama';

  @override
  String get panoramaRearrange => 'Rearrange spaces by most recent use';

  @override
  String get panoramaSwitchToApp => 'Switch to a space with the app\'s windows';

  @override
  String get panoramaGroupByApp => 'Group windows by app';

  @override
  String get panoramaSeparateSpaces => 'Displays have separate spaces';

  @override
  String get hotCornerNone => '—';

  @override
  String get wallpaperRestartNote =>
      'The desktop reads the wallpaper when the session starts.';

  @override
  String get wallpaperFill => 'Fill screen';

  @override
  String get wallpaperSilica => 'Silica';

  @override
  String get wallpaperSilicaName => 'Dunes at twilight';

  @override
  String get wallpaperColors => 'Colours';

  @override
  String get wallpaperPictures => 'Your Pictures';

  @override
  String get wallpaperScreenSaver => 'Screen Saver…';

  @override
  String get searchDescription =>
      'Choose what Faro, the search panel, looks through.';

  @override
  String get searchHelpImprove => 'Help improve search';

  @override
  String get searchShowRelated => 'Show related content';

  @override
  String get searchResultsFromApps => 'Results from apps';

  @override
  String get searchApplications => 'Applications';

  @override
  String get searchFolders => 'Folders';

  @override
  String get searchCalculator => 'Calculations and conversions';

  @override
  String get notificationsDescription =>
      'Choose how apps can get your attention.';

  @override
  String get notificationsCenter => 'Notification Center';

  @override
  String get notificationsPreviews => 'Show previews';

  @override
  String get notificationsWhenUnlocked => 'When unlocked';

  @override
  String get notificationsWhenSleeping =>
      'Allow notifications when the display is sleeping';

  @override
  String get notificationsWhenLocked =>
      'Allow notifications when the screen is locked';

  @override
  String get notificationsWhenMirroring =>
      'Allow notifications when mirroring or sharing the display';

  @override
  String get notificationsApps => 'Application notifications';

  @override
  String get notificationsAppsNone => 'No apps have sent notifications';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundAlert => 'Alert sound';

  @override
  String get soundAlertDefault => 'Default';

  @override
  String get soundAlertVolume => 'Alert volume';

  @override
  String get soundStartup => 'Play sound on startup';

  @override
  String get soundInterface => 'Play user interface sound effects';

  @override
  String get soundVolumeFeedback => 'Play feedback when volume is changed';

  @override
  String get soundOutput => 'Output';

  @override
  String get soundOutputDevice => 'Output device';

  @override
  String get soundNoAudio => 'No audio service found.';

  @override
  String get soundOutputVolume => 'Output volume';

  @override
  String get soundMute => 'Mute';

  @override
  String get soundInput => 'Input';

  @override
  String get soundInputLevel => 'Input volume';

  @override
  String get focusDoNotDisturb => 'Do Not Disturb';

  @override
  String get focusWork => 'Work';

  @override
  String get focusReduceInterruptions => 'Fewer interruptions';

  @override
  String get focusSleep => 'Sleep';

  @override
  String get focusStudy => 'Study';

  @override
  String get focusShareAcrossDevices => 'Share across devices';

  @override
  String get focusStatus => 'Focus status';

  @override
  String get screenTimeActivity => 'Activity';

  @override
  String get screenTimeAppUsage => 'App and website activity';

  @override
  String get screenTimeNotifications => 'Notifications';

  @override
  String get screenTimeLimits => 'Limits';

  @override
  String get screenTimeDowntime => 'Downtime';

  @override
  String get screenTimeAppLimits => 'App limits';

  @override
  String get screenTimeAppActivity => 'Share app and website activity';

  @override
  String get lockDisplayOff => 'Turn the display off when inactive';

  @override
  String get lockPasswordDelay =>
      'Require password after sleep or screen saver';

  @override
  String get lockSavedForLater =>
      'Silica has no lock screen yet: these choices are saved for it.';

  @override
  String get lockNever => 'Never';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String get lockShowUser => 'Show user name and photo';

  @override
  String get lockShowHints => 'Show password hints';

  @override
  String get lockShowMessage => 'Show a message when locked';

  @override
  String get lockLoginWindowShows => 'Login window shows';

  @override
  String get lockListOfUsers => 'List of users';

  @override
  String get lockNameAndPassword => 'Name and password';

  @override
  String get lockShowPowerButtons =>
      'Show the sleep, restart and shut down buttons';

  @override
  String get privacyDescription =>
      'Control which apps can use your location, camera, microphone and files.';

  @override
  String get privacyLocation => 'Location';

  @override
  String get privacyCamera => 'Camera';

  @override
  String get privacyMicrophone => 'Microphone';

  @override
  String get privacyScreenRecording => 'Screen recording';

  @override
  String get privacyFiles => 'Files and folders';

  @override
  String get passwordLogin => 'Login password';

  @override
  String get passwordSet => 'A password is set for your account';

  @override
  String get passwordChange => 'Change…';

  @override
  String get passwordFingerprint => 'Use a fingerprint to unlock';

  @override
  String get usersAdmin => 'Admin';

  @override
  String get usersYou => 'You';

  @override
  String get usersGuest => 'Guest user';

  @override
  String get usersAutomaticLogin => 'Automatically log in as';

  @override
  String get usersAddGroup => 'Add Group…';

  @override
  String get usersAddUser => 'Add User…';

  @override
  String get accountsNone => 'No internet accounts';

  @override
  String get accountsAdd => 'Add Account…';

  @override
  String get keyboardRepeatRate => 'Key repeat rate';

  @override
  String get keyboardRepeatDelay => 'Delay until repeat';

  @override
  String get keyboardRepeatNote =>
      'Ossido applies these to the keys held down in every app.';

  @override
  String get keyboardOff => 'Off';

  @override
  String get keyboardSlow => 'Slow';

  @override
  String get keyboardFast => 'Fast';

  @override
  String get keyboardLong => 'Long';

  @override
  String get keyboardShort => 'Short';

  @override
  String get keyboardGlobeKey => 'Press the function key to';

  @override
  String get keyboardDoNothing => 'Do nothing';

  @override
  String get keyboardNavigation => 'Keyboard navigation';

  @override
  String get keyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get keyboardShortcutsButton => 'Keyboard Shortcuts…';

  @override
  String get keyboardTextInput => 'Text input';

  @override
  String get keyboardInputSources => 'Input sources';

  @override
  String get keyboardInputSourcesValue => 'The system layout';

  @override
  String get keyboardTextReplacements => 'Text replacements';

  @override
  String get keyboardDictation => 'Dictation';

  @override
  String get shortcutsReadOnly =>
      'These shortcuts can\'t be changed from Settings yet. Logo is the key with the system logo.';

  @override
  String get shortcutsScreenshots => 'Screenshots';

  @override
  String get shortcutsSpaces => 'Spaces and Panorama';

  @override
  String get shortcutsApps => 'Apps';

  @override
  String get shortcutsWindows => 'Windows';

  @override
  String get shortcutsSession => 'Session';

  @override
  String get shortcutScreen => 'Picture of the whole screen';

  @override
  String get shortcutSelection => 'Picture of a selected area';

  @override
  String get shortcutTools => 'Screenshot and recording tools';

  @override
  String get shortcutPanorama => 'Show Panorama';

  @override
  String get shortcutAppWindows => 'Show the app\'s windows';

  @override
  String get shortcutShowDesktop => 'Show the desktop';

  @override
  String get shortcutPreviousSpace => 'Previous space';

  @override
  String get shortcutNextSpace => 'Next space';

  @override
  String get shortcutSearch => 'Open Faro';

  @override
  String get shortcutNextApp => 'Next app';

  @override
  String get shortcutPreviousApp => 'Previous app';

  @override
  String get shortcutQuitApp => 'Quit the app';

  @override
  String get shortcutForceQuit => 'Force quit';

  @override
  String get shortcutCloseWindow => 'Close the window';

  @override
  String get shortcutMinimize => 'Minimise the window';

  @override
  String get shortcutFullScreen => 'Full screen';

  @override
  String get shortcutLogOut => 'End the session';

  @override
  String get mousePointerSpeed => 'Pointer speed';

  @override
  String get mouseNaturalScrolling => 'Natural scrolling';

  @override
  String get mouseSecondaryClick => 'Secondary click';

  @override
  String get mouseRightButton => 'Right button';

  @override
  String get mouseDoubleClickSpeed => 'Double-click speed';

  @override
  String get mouseScrollSpeed => 'Scrolling speed';

  @override
  String get printersDefault => 'Default printer';

  @override
  String get printersLastUsed => 'Last printer used';

  @override
  String get printersPaperSize => 'Default paper size';

  @override
  String get printersNone => 'No printers';

  @override
  String get printersIsDefault => 'Default';

  @override
  String get printersAdd => 'Add Printer…';

  @override
  String aboutDisplayN(int number) {
    return 'Display $number';
  }

  @override
  String aboutProcessorCount(String name, int count) {
    return '$name ($count cores)';
  }

  @override
  String storageAvailableOf(String available, String total) {
    return '$available available of $total';
  }

  @override
  String lockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String lockHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String lockSeconds(int count) {
    return '$count seconds';
  }
}
