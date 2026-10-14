// Lock Screen (ST-LCK-01), Privacy and Security (ST-PRV-01), Login Password (ST-USR-01), Users
// and Groups (ST-USR-01), Internet Accounts (ST-ACN-01), Accessibility (ST-ACC-01/02) and
// Search (ST-SPT-01). Real: the current user (passwd) and the lock screen choices, saved in
// lockscreen.json for the lock screen Silica does not have yet (the footer says so). The
// rest has no backend yet.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

class LockScreenPane extends StatefulWidget {
  const LockScreenPane({super.key});

  @override
  State<LockScreenPane> createState() => _LockScreenPaneState();
}

class _LockScreenPaneState extends State<LockScreenPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ServicesScope.of(context).config;
    int minutes(String key, int fallback) =>
        config.number('lockscreen', key, fallback: fallback.toDouble()).round();
    bool flag(String key, bool fallback) =>
        config.flag('lockscreen', key, fallback: fallback);
    void set(String key, Object value) =>
        setState(() => config.write('lockscreen', key, value));
    String duration(int m) => m == 0
        ? l.lockNever
        : m < 60
        ? l.lockMinutes(m)
        : l.lockHours(m ~/ 60);
    String delay(int s) => s == 0
        ? l.lockImmediately
        : s < 60
        ? l.lockSeconds(s)
        : s < 3600
        ? l.lockMinutes(s ~/ 60)
        : l.lockHours(s ~/ 3600);
    // The values read on the reference machine are the defaults: 30 minutes, 15 minutes.
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.lockSavedForLater,
          children: [
            PopUpRow<int>(
              key: const ValueKey('display off'),
              title: l.lockDisplayOff,
              items: [
                for (final m in [1, 2, 5, 10, 20, 30, 60, 180, 0])
                  PopUpItem(m, duration(m)),
              ],
              value: minutes('displayOffMinutes', 30),
              onChanged: (m) => set('displayOffMinutes', m),
            ),
            PopUpRow<int>(
              key: const ValueKey('password delay'),
              title: l.lockPasswordDelay,
              items: [
                for (final s in [0, 5, 60, 300, 900, 3600, 28800])
                  PopUpItem(s, delay(s)),
              ],
              value: minutes('passwordDelaySeconds', 900),
              onChanged: (s) => set('passwordDelaySeconds', s),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            SwitchRow(
              title: l.lockShowUser,
              value: flag('showUser', true),
              onChanged: (v) => set('showUser', v),
            ),
            SwitchRow(
              title: l.lockShowHints,
              value: flag('showHints', false),
              onChanged: (v) => set('showHints', v),
            ),
            SwitchRow(
              title: l.lockShowMessage,
              value: flag('showMessage', false),
              onChanged: (v) => set('showMessage', v),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            ValueRow(
              title: l.lockLoginWindowShows,
              trailing: SilicaRadioGroup<String>(
                options: [
                  RadioOption('list', l.lockListOfUsers),
                  RadioOption('fields', l.lockNameAndPassword),
                ],
                value: config.text(
                  'lockscreen',
                  'loginWindow',
                  fallback: 'list',
                ),
                onChanged: (v) => set('loginWindow', v),
              ),
            ),
            SwitchRow(
              title: l.lockShowPowerButtons,
              value: flag('showPowerButtons', true),
              onChanged: (v) => set('showPowerButtons', v),
            ),
          ],
        ),
      ],
    );
  }
}

class PrivacyPane extends StatelessWidget {
  const PrivacyPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.privacy.symbol,
          tint: PaneId.privacy.tint,
          title: l.panePrivacy,
          description: l.privacyDescription,
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            for (final (title, symbol) in [
              (l.privacyLocation, 'location'),
              (l.privacyCamera, 'camera'),
              (l.privacyMicrophone, 'mic'),
              (l.privacyScreenRecording, 'record-circle'),
              (l.privacyFiles, 'folder'),
            ])
              NavRow(title: title, symbol: symbol, tint: PaneId.privacy.tint),
          ],
        ),
      ],
    );
  }
}

class PasswordPane extends StatelessWidget {
  const PasswordPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          children: [
            ButtonRow(
              title: l.passwordLogin,
              subtitle: l.passwordSet,
              label: l.passwordChange,
            ),
            SwitchRow(title: l.passwordFingerprint, value: false),
          ],
        ),
      ],
    );
  }
}

class UsersPane extends StatelessWidget {
  const UsersPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    final colors = SettingsColors.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ValueRow(
              key: const ValueKey('current user'),
              height: 52,
              title: info.userName.isEmpty ? l.accountLocalUser : info.userName,
              subtitle: info.userLogin.isEmpty
                  ? l.usersAdmin
                  : '${info.userLogin} · ${l.usersAdmin}',
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8E8E93),
                ),
                alignment: Alignment.center,
                child: SettingsSymbol(
                  'person-fill',
                  color: const Color(0xFFFFFFFF),
                  size: 18,
                ),
              ),
              trailing: Text(
                l.usersYou,
                style: settingsText(11, colors.secondary),
              ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            SwitchRow(title: l.usersGuest, value: false),
            PopUpRow<int>(
              title: l.usersAutomaticLogin,
              items: [PopUpItem(0, l.lockNever)],
              value: 0,
            ),
          ],
        ),
        ButtonBar(
          buttons: [
            SilicaButton(label: l.usersAddGroup, onPressed: null),
            SilicaButton(label: l.usersAddUser, onPressed: null),
          ],
        ),
      ],
    );
  }
}

class InternetAccountsPane extends StatelessWidget {
  const InternetAccountsPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          children: [EmptyState(l.accountsNone)],
        ),
        ButtonBar(
          buttons: [SilicaButton(label: l.accountsAdd, onPressed: null)],
        ),
      ],
    );
  }
}

class AccessibilityPane extends StatelessWidget {
  const AccessibilityPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const blue = Color(0xFF0A84FF);
    Widget group(String heading, List<(String, String)> rows) => SettingsGroup(
      heading: heading,
      unavailable: true,
      children: [
        for (final (title, symbol) in rows)
          NavRow(title: title, symbol: symbol, tint: blue),
      ],
    );
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.accessibility.symbol,
          tint: PaneId.accessibility.tint,
          title: l.paneAccessibility,
          description: l.accessibilityDescription,
        ),
        group(l.accessibilityVision, [
          (l.accessibilityScreenReader, 'speaker'),
          (l.accessibilityZoom, 'search'),
          (l.accessibilityLargerText, 'text-size'),
          (l.accessibilityDisplay, 'display'),
          (l.accessibilityMotion, 'circle-dot'),
          (l.accessibilitySpokenContent, 'speaker'),
        ]),
        group(l.accessibilityPhysical, [
          (l.accessibilityVoiceControl, 'mic'),
          (l.paneKeyboard, 'keyboard'),
          (l.accessibilityPointer, 'mouse'),
        ]),
        group(l.accessibilityHearing, [
          (l.accessibilityAudio, 'speaker'),
          (l.accessibilityCaptions, 'captions'),
        ]),
      ],
    );
  }
}

class SearchPane extends StatelessWidget {
  const SearchPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.search.symbol,
          tint: PaneId.search.tint,
          title: l.paneSearch,
          description: l.searchDescription,
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            SwitchRow(title: l.searchHelpImprove, value: false),
            SwitchRow(title: l.searchShowRelated, value: true),
          ],
        ),
        SettingsGroup(
          heading: l.searchResultsFromApps,
          unavailable: true,
          children: [
            SwitchRow(title: l.searchApplications, value: true),
            SwitchRow(title: l.searchFolders, value: true),
            SwitchRow(title: l.searchCalculator, value: true),
          ],
        ),
      ],
    );
  }
}
