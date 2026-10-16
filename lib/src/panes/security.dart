// Lock Screen (ST-LCK-01), Privacy and Security (ST-PRV-01), Login Password (ST-USR-01), Users
// and Groups (ST-USR-01), Internet Accounts (ST-ACN-01), Accessibility (ST-ACC-01/02) and
// Search (ST-SPT-01). Real: the user accounts (passwd and group, administrators from wheel).
// Silica has no lock screen yet (#50), and the accounts, privacy, accessibility and search
// settings wait for their backends: each group names its issue. The Lock Screen's display-off
// time is power.json's, which Ossido reads (#68).

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../model/issues.dart';
import '../system/tools.dart';
import '../ui/grouped.dart';
import 'power.dart' show idleRow;

class LockScreenPane extends StatefulWidget {
  const LockScreenPane({super.key});

  @override
  State<LockScreenPane> createState() => _LockScreenPaneState();
}

class _LockScreenPaneState extends State<LockScreenPane> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The display turns off by power.json (Ossido, #68); the lock itself has no screen yet.
    return PanePage(
      children: [
        SettingsGroup(
          footer: l.notAvailableYet,
          children: [
            idleRow(
              context,
              key: const ValueKey('lock display off'),
              title: l.lockDisplayOff,
              configKey: 'displayOffMinutes',
              changed: () => setState(() {}),
            ),
            // The reference machine's value is shown: 15 minutes.
            Unavailable(
              child: PopUpRow<int>(
                title: l.lockPasswordDelay,
                items: [PopUpItem(900, l.lockMinutes(15))],
                value: 900,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.lockScreen,
          children: [
            SwitchRow(title: l.lockShowUser, value: true),
            SwitchRow(title: l.lockShowHints, value: false),
            SwitchRow(title: l.lockShowMessage, value: false),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.lockScreen,
          children: [
            ValueRow(
              title: l.lockLoginWindowShows,
              alignTop: true,
              trailing: SettingsRadioGroup<String>(
                options: [
                  RadioOption('list', l.lockListOfUsers),
                  RadioOption('fields', l.lockNameAndPassword),
                ],
                value: 'list',
                onChanged: (_) {},
              ),
            ),
            SwitchRow(title: l.lockShowPowerButtons, value: true),
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
          issue: Issues.privacy,
          children: [
            for (final (title, symbol) in [
              (l.privacyLocation, 'location'),
              (l.privacyCamera, 'camera'),
              (l.privacyMicrophone, 'mic'),
              (l.privacyScreenRecording, 'record-circle'),
              (l.privacyFiles, 'folder'),
            ])
              NavRow(
                title: title,
                symbol: symbol,
                tint: PaneId.privacy.tint,
                onTap: () {},
              ),
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
          issue: Issues.users,
          children: [
            ButtonRow(
              title: l.passwordLogin,
              subtitle: l.passwordSet,
              label: l.passwordChange,
              onPressed: () {},
            ),
            SwitchRow(title: l.passwordFingerprint, value: false),
          ],
        ),
      ],
    );
  }
}

class UsersPane extends StatefulWidget {
  const UsersPane({super.key});

  @override
  State<UsersPane> createState() => _UsersPaneState();
}

class _UsersPaneState extends State<UsersPane> {
  List<UserAccount>? _users;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_users == null) {
      ServicesScope.of(context).tools.users().then((u) {
        if (mounted) setState(() => _users = u);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = HostInfoScope.of(context);
    final colors = SettingsColors.of(context);
    final users = [...?_users];
    // Without passwd entries (a container), the session's user still shows.
    if (users.isEmpty && info.userLogin.isNotEmpty) {
      users.add(
        UserAccount(
          login: info.userLogin,
          name: info.userName,
          uid: 0,
          admin: true,
        ),
      );
    }
    users.sort((a, b) {
      if (a.login == info.userLogin) return -1;
      if (b.login == info.userLogin) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    Widget avatar(UserAccount u) => Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA5A5AA), Color(0xFF85858B)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        (u.name.isEmpty ? u.login : u.name).characters.first.toUpperCase(),
        style: settingsText(
          14,
          const Color(0xFFFFFFFF),
          weight: FontWeight.w600,
        ),
      ),
    );
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            for (final u in users)
              ValueRow(
                key: ValueKey(
                  u.login == info.userLogin
                      ? 'current user'
                      : 'user ${u.login}',
                ),
                height: 52,
                title: u.name,
                subtitle: [
                  u.login,
                  u.admin ? l.usersAdmin : l.usersStandard,
                ].join(' · '),
                leading: avatar(u),
                trailing: u.login == info.userLogin
                    ? Text(
                        l.usersYou,
                        style: settingsText(11, colors.secondary),
                      )
                    : null,
              ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          issue: Issues.users,
          children: [
            SwitchRow(title: l.usersGuest, value: false),
            PopUpRow<int>(
              title: l.usersAutomaticLogin,
              items: [PopUpItem(0, l.lockNever)],
              value: 0,
              onChanged: (_) {},
            ),
            ButtonRow(
              title: l.usersAddUser,
              label: l.addButton,
              onPressed: () {},
            ),
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
          issue: Issues.internetAccounts,
          children: [
            EmptyState(l.accountsNone),
            ButtonRow(
              title: l.accountsAdd,
              label: l.addButton,
              onPressed: () {},
            ),
          ],
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
    const blue = Color(0xFF0E77E6);
    Widget group(String heading, List<(String, String)> rows) => SettingsGroup(
      heading: heading,
      unavailable: true,
      issue: Issues.accessibility,
      children: [
        for (final (title, symbol) in rows)
          NavRow(title: title, symbol: symbol, tint: blue, onTap: () {}),
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
          issue: Issues.search,
          children: [
            SwitchRow(title: l.searchHelpImprove, value: false),
            SwitchRow(title: l.searchShowRelated, value: true),
          ],
        ),
        SettingsGroup(
          heading: l.searchResultsFromApps,
          unavailable: true,
          issue: Issues.search,
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
