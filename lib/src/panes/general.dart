// General (ST-GEN-01..03): the header card and the navigation rows to its sub-panes. About,
// Storage, Sharing (the computer name), Date and Time and Language and Region show the real
// machine; changing them, software updates, login items, backups and reset have no backend
// yet. The reference's warranty, device management and password autofill rows belong to its
// own services and are left out.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/panes.dart';
import '../services.dart';
import '../style.dart';
import '../system/host.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

/// Bytes in decimal units, as storage is sold ("512 GB").
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

class GeneralPane extends StatelessWidget {
  const GeneralPane({super.key, required this.open});

  final ValueChanged<SubPaneId> open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    NavRow row(SubPaneId sub, String title, String symbol, Color tint) =>
        NavRow(
          key: ValueKey('general ${sub.name}'),
          title: title,
          symbol: symbol,
          tint: tint,
          onTap: () => open(sub),
        );
    const gray = Color(0xFF8E8E93);
    const blue = Color(0xFF0A84FF);
    return PanePage(
      children: [
        HeaderCard(
          symbol: PaneId.general.symbol,
          tint: PaneId.general.tint,
          title: l.paneGeneral,
          description: l.generalDescription,
          centered: true,
        ),
        SettingsGroup(
          children: [row(SubPaneId.about, l.subAbout, 'desktop', gray)],
        ),
        SettingsGroup(
          children: [
            row(
              SubPaneId.softwareUpdate,
              l.subSoftwareUpdate,
              'arrow-clockwise',
              gray,
            ),
            row(SubPaneId.storage, l.subStorage, 'circle-stack', gray),
          ],
        ),
        SettingsGroup(
          children: [row(SubPaneId.sharing, l.subSharing, 'person-2', blue)],
        ),
        SettingsGroup(
          children: [
            row(SubPaneId.dateTime, l.subDateTime, 'calendar', blue),
            row(SubPaneId.startupDisk, l.subStartupDisk, 'circle-stack', gray),
            row(SubPaneId.loginItems, l.subLoginItems, 'checklist', gray),
            row(SubPaneId.languageRegion, l.subLanguageRegion, 'globe', blue),
            row(SubPaneId.backups, l.subBackups, 'clock', gray),
          ],
        ),
        SettingsGroup(
          children: [
            row(
              SubPaneId.transferReset,
              l.subTransferReset,
              'arrow-counterclockwise',
              gray,
            ),
          ],
        ),
      ],
    );
  }
}

/// A sub-pane of General.
Widget generalSubPane(SubPaneId sub) => switch (sub) {
  SubPaneId.about => const AboutPane(),
  SubPaneId.storage => const StoragePane(),
  SubPaneId.sharing => const _SharingPane(),
  SubPaneId.dateTime => const _DateTimePane(),
  SubPaneId.languageRegion => const _LanguagePane(),
  SubPaneId.softwareUpdate => const _SoftwareUpdatePane(),
  SubPaneId.startupDisk ||
  SubPaneId.loginItems ||
  SubPaneId.backups ||
  SubPaneId.transferReset => const _UnavailableSubPane(),
};

/// General › About (ST-GEN-02): the product card, the specification table, the displays and
/// the storage.
class AboutPane extends StatelessWidget {
  const AboutPane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final info = services.info;
    final colors = SettingsColors.of(context);
    final model = [
      info.vendor,
      info.model,
    ].where((s) => s.isNotEmpty).join(' ');
    final displays = PlatformDispatcher.instance.displays.toList();
    String unknown(String s) => s.isEmpty ? l.aboutUnknown : s;
    return PanePage(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.group,
            borderRadius: BorderRadius.circular(SettingsMetrics.groupRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const IconTile(
                  symbol: 'desktop',
                  tint: Color(0xFF8E8E93),
                  size: 72,
                ),
                const SizedBox(height: 10),
                Text(
                  info.hostname.isEmpty ? l.aboutThisComputer : info.hostname,
                  key: const ValueKey('about name'),
                  style: settingsText(17, colors.text, weight: FontWeight.w600),
                ),
                if (model.isNotEmpty)
                  Text(model, style: settingsText(12, colors.secondary)),
              ],
            ),
          ),
        ),
        SettingsGroup(
          children: [
            ValueRow(
              title: l.aboutName,
              trailing: _Value(unknown(info.hostname)),
            ),
            ValueRow(
              title: l.aboutProcessor,
              trailing: _Value(
                info.cpu.isEmpty
                    ? l.aboutUnknown
                    : info.cpuCount > 1
                    ? l.aboutProcessorCount(info.cpu, info.cpuCount)
                    : info.cpu,
              ),
            ),
            ValueRow(
              title: l.aboutMemory,
              trailing: _Value(
                info.memoryBytes == 0
                    ? l.aboutUnknown
                    : formatBytes(info.memoryBytes),
              ),
            ),
            ValueRow(
              title: l.aboutSystem,
              trailing: _Value(unknown(info.osPrettyName)),
            ),
            ValueRow(
              title: l.aboutKernel,
              trailing: _Value(unknown(info.kernel)),
            ),
          ],
        ),
        SettingsGroup(
          heading: l.aboutDisplays,
          children: [
            if (displays.isEmpty)
              ValueRow(title: l.aboutUnknown)
            else
              for (final (i, d) in displays.indexed)
                ValueRow(
                  title: l.aboutDisplayN(i + 1),
                  trailing: _Value(
                    '${d.size.width.round()} × ${d.size.height.round()}'
                    '${d.refreshRate > 0 ? ' · ${d.refreshRate.round()} Hz' : ''}',
                  ),
                ),
          ],
        ),
        const _DiskGroup(),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 300),
    child: Text(
      text,
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: settingsText(13, SettingsColors.of(context).secondary),
    ),
  );
}

/// The system disk: a usage bar and the free space (df).
class _DiskGroup extends StatefulWidget {
  const _DiskGroup();

  @override
  State<_DiskGroup> createState() => _DiskGroupState();
}

class _DiskGroupState extends State<_DiskGroup> {
  Future<DiskUsage?>? _disk;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disk ??= ServicesScope.of(context).host.disk();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<DiskUsage?>(
      future: _disk,
      builder: (context, snapshot) {
        final disk = snapshot.data;
        return SettingsGroup(
          heading: l.subStorage,
          children: [
            if (disk == null)
              ValueRow(
                title: snapshot.connectionState == ConnectionState.done
                    ? l.aboutUnknown
                    : l.storageCalculating,
              )
            else
              ValueRow(
                key: const ValueKey('disk'),
                title: l.storageSystemDisk,
                subtitle: l.storageAvailableOf(
                  formatBytes(disk.available),
                  formatBytes(disk.total),
                ),
                trailing: SilicaProgressBar(
                  value: disk.total == 0 ? 0 : disk.used / disk.total,
                  width: 200,
                  semanticLabel: l.subStorage,
                ),
              ),
          ],
        );
      },
    );
  }
}

class StoragePane extends StatelessWidget {
  const StoragePane({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PanePage(
      children: [
        const _DiskGroup(),
        SettingsGroup(
          heading: l.storageRecommendations,
          unavailable: true,
          children: [ButtonRow(title: l.storageEmptyTrash, label: l.empty)],
        ),
      ],
    );
  }
}

class _SharingPane extends StatelessWidget {
  const _SharingPane();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    return PanePage(
      children: [
        SettingsGroup(
          unavailable: true,
          children: [
            SwitchRow(title: l.sharingFiles, value: false),
            SwitchRow(title: l.sharingScreen, value: false),
            SwitchRow(title: l.sharingRemoteLogin, value: false),
          ],
        ),
        SettingsGroup(
          footer: l.sharingNameReadOnly,
          children: [
            ValueRow(
              title: l.sharingComputerName,
              trailing: _Value(
                info.hostname.isEmpty ? l.aboutUnknown : info.hostname,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimePane extends StatelessWidget {
  const _DateTimePane();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ValueRow(
              title: l.dateTimeZone,
              trailing: _Value(
                info.timezone.isEmpty ? l.aboutUnknown : info.timezone,
              ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            SwitchRow(title: l.dateTimeAutomatic, value: true),
            SwitchRow(title: l.dateTime24Hour, value: true),
          ],
        ),
      ],
    );
  }
}

class _LanguagePane extends StatelessWidget {
  const _LanguagePane();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    return PanePage(
      children: [
        SettingsGroup(
          heading: l.languagePreferred,
          footer: l.languageReadOnly,
          children: [
            ValueRow(
              title: info.language.isEmpty ? l.aboutUnknown : info.language,
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            PopUpRow<int>(
              title: l.languageRegion,
              items: [PopUpItem(0, l.aboutUnknown)],
              value: 0,
            ),
            PopUpRow<int>(
              title: l.languageFirstDay,
              items: [PopUpItem(0, l.languageMonday)],
              value: 0,
            ),
          ],
        ),
      ],
    );
  }
}

class _SoftwareUpdatePane extends StatelessWidget {
  const _SoftwareUpdatePane();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = ServicesScope.of(context).info;
    return PanePage(
      children: [
        SettingsGroup(
          children: [
            ValueRow(
              title: l.updateInstalled,
              trailing: _Value(
                info.osPrettyName.isEmpty ? l.aboutUnknown : info.osPrettyName,
              ),
            ),
          ],
        ),
        SettingsGroup(
          unavailable: true,
          children: [
            ButtonRow(title: l.updateCheck, label: l.updateCheckButton),
            SwitchRow(title: l.updateAutomatic, value: false),
          ],
        ),
      ],
    );
  }
}

class _UnavailableSubPane extends StatelessWidget {
  const _UnavailableSubPane();

  @override
  Widget build(BuildContext context) => PanePage(
    children: [
      SettingsGroup(
        children: [
          EmptyState(
            AppLocalizations.of(context).notAvailableYet,
            key: const ValueKey('unavailable'),
          ),
        ],
      ),
    ],
  );
}
