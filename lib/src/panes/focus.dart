// Focus (ST-FOC-01): Do Not Disturb and the Focus modes. Silica-daemon turns a Focus on
// (`SetFocus`: `dnd`, a mode's id, or none), silences banners in every one, and reports the
// active mode in its state; the modes themselves are Settings' to keep in focus.json: a name, a
// symbol, the apps and the people allowed through. Letting the allowed apps through is the
// shell's to do (#72); the pane says so.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../model/issues.dart';
import '../services.dart';
import '../style.dart';
import '../system/settings_files.dart';
import '../system/tools.dart';
import '../ui/grouped.dart';
import '../ui/symbol.dart';

/// The symbols a Focus can wear (silica-icons).
const List<String> focusSymbols = [
  'moon',
  'moon-stars',
  'person',
  'bell-slash',
  'lightbulb',
  'house',
  'book',
  'gamecontroller',
  'music-note',
  'leaf',
  'heart',
  'airplane',
];

const Color _focusTint = Color(0xFF8B5CF6);

class FocusPane extends StatefulWidget {
  const FocusPane({super.key});

  @override
  State<FocusPane> createState() => _FocusPaneState();
}

class _FocusPaneState extends State<FocusPane> {
  List<NotifyingApp> _apps = const [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      ServicesScope.of(context).tools.notifyingApps().then((apps) {
        if (mounted) setState(() => _apps = apps);
      });
    }
  }

  /// Opens the editor for [mode] (a new one when null) and applies what it returns.
  Future<void> _edit(FocusMode? mode, String active) async {
    final services = ServicesScope.of(context);
    final modes = services.config.focusModes;
    final result = await showAmalfiSheet<_Edit>(
      context,
      semanticLabel: mode == null
          ? AppLocalizations.of(context).focusNewTitle
          : AppLocalizations.of(context).focusEditTitle,
      builder: (context, sheet) =>
          _FocusSheet(mode: mode, apps: _apps, close: sheet.close),
    );
    if (result == null || !mounted) return;
    final saved = services.config.focusModes;
    if (result.delete) {
      if (mode == null) return;
      // Turn it off first: the daemon would refuse to keep a mode it can no longer find.
      if (active == mode.id) await services.system.setFocus('');
      services.config.writeFocusModes([
        for (final m in saved)
          if (m.id != mode.id) m,
      ]);
    } else if (result.mode case final edited?) {
      if (mode == null) {
        if (saved.length >= FocusMode.maxModes) return;
        final id = FocusMode.idFor(edited.name, [for (final m in modes) m.id]);
        services.config.writeFocusModes([
          ...saved,
          FocusMode(
            id: id,
            name: edited.name,
            symbol: edited.symbol,
            allowedApps: edited.allowedApps,
            allowedPeople: edited.allowedPeople,
          ),
        ]);
      } else {
        services.config.writeFocusModes([
          for (final m in saved) m.id == mode.id ? edited : m,
        ]);
        // The daemon reads the mode when it is turned on: tell it about the change.
        if (active == mode.id) await services.system.setFocus(mode.id);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = ServicesScope.of(context);
    final system = services.system;
    return SystemStateBuilder(
      builder: (context, state) {
        final modes = services.config.focusModes;
        return PanePage(
          children: [
            SettingsGroup(
              footer: state.reachable
                  ? l.focusDoNotDisturbHelp
                  : l.appearanceNoDaemon,
              children: [
                ValueRow(
                  title: l.focusDoNotDisturb,
                  subtitle: state.doNotDisturb ? l.on : null,
                  height: 52,
                  leading: const IconTile(
                    symbol: 'moon',
                    tint: _focusTint,
                    size: 28,
                  ),
                  trailing: AmalfiSwitch(
                    key: const ValueKey('dnd switch'),
                    value: state.doNotDisturb,
                    size: AmalfiControlSize.mini,
                    semanticLabel: l.focusDoNotDisturb,
                    onChanged: state.reachable
                        ? (on) => system.setDoNotDisturb(on)
                        : null,
                  ),
                ),
              ],
            ),
            SettingsGroup(
              heading: l.focusModesHeading,
              footer: [
                l.focusModesNote,
                if (modes.length >= FocusMode.maxModes) l.focusTooMany,
              ].join(' '),
              children: [
                if (modes.isEmpty) EmptyState(l.focusNoModes),
                for (final mode in modes)
                  ValueRow(
                    key: ValueKey('focus mode ${mode.id}'),
                    title: mode.name,
                    subtitle: state.focus == mode.id
                        ? l.on
                        : l.focusSummary(
                            mode.allowedApps.length,
                            mode.allowedPeople.length,
                          ),
                    height: 52,
                    leading: IconTile(
                      symbol: mode.symbol,
                      tint: _focusTint,
                      size: 28,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AmalfiPushButton(
                          label: l.edit,
                          size: AmalfiControlSize.small,
                          onPressed: () => _edit(mode, state.focus),
                        ),
                        const SizedBox(width: 12),
                        AmalfiSwitch(
                          value: state.focus == mode.id,
                          size: AmalfiControlSize.mini,
                          semanticLabel: l.focusTurnOn(mode.name),
                          onChanged: state.reachable
                              ? (on) => system.setFocus(on ? mode.id : '')
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ButtonBar(
              buttons: [
                AmalfiPushButton(
                  key: const ValueKey('add focus'),
                  label: l.focusAdd,
                  size: AmalfiControlSize.small,
                  onPressed: modes.length >= FocusMode.maxModes
                      ? null
                      : () => _edit(null, state.focus),
                ),
              ],
            ),
            SettingsGroup(
              unavailable: true,
              issue: Issues.focus,
              children: [
                NavRow(title: l.focusStatus, value: l.on, onTap: () {}),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// What the editor returns: the mode as edited, or its deletion.
class _Edit {
  const _Edit.save(FocusMode this.mode) : delete = false;
  const _Edit.delete() : mode = null, delete = true;
  final FocusMode? mode;
  final bool delete;
}

class _FocusSheet extends StatefulWidget {
  const _FocusSheet({
    required this.mode,
    required this.apps,
    required this.close,
  });

  final FocusMode? mode;
  final List<NotifyingApp> apps;
  final void Function([_Edit?]) close;

  @override
  State<_FocusSheet> createState() => _FocusSheetState();
}

class _FocusSheetState extends State<_FocusSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.mode?.name ?? '',
  );
  final TextEditingController _person = TextEditingController();
  late String _symbol = widget.mode?.symbol ?? focusSymbols.first;
  late final List<String> _apps = [...?widget.mode?.allowedApps];
  late final List<String> _people = [...?widget.mode?.allowedPeople];

  @override
  void dispose() {
    _name.dispose();
    _person.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _person.text.trim();
    if (name.isEmpty || _people.contains(name)) return;
    setState(() {
      _people.add(name);
      _person.clear();
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    // A name still typed in the field counts.
    final typed = _person.text.trim();
    final people = [
      ..._people,
      if (typed.isNotEmpty && !_people.contains(typed)) typed,
    ];
    widget.close(
      _Edit.save(
        FocusMode(
          id: widget.mode?.id ?? '',
          name: name,
          symbol: _symbol,
          allowedApps: _apps,
          allowedPeople: people,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = SettingsColors.of(context);
    final accent = ControlAccent.of(context);
    // The apps that sent notifications, then the ones allowed before that no longer show.
    final known = {for (final a in widget.apps) a.key: a.name};
    final appKeys = [
      for (final a in widget.apps) a.key,
      for (final k in _apps)
        if (!known.containsKey(k)) k,
    ];
    return SizedBox(
      width: 480,
      height: 560,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.mode == null ? l.focusNewTitle : l.focusEditTitle,
              style: settingsText(13, colors.text, weight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  GroupBox(
                    child: ValueRow(
                      title: l.focusName,
                      trailing: SizedBox(
                        width: 240,
                        child: AmalfiTextField(
                          key: const ValueKey('focus name'),
                          controller: _name,
                          semanticLabel: l.focusName,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                    ),
                  ),
                  SectionHeading(l.focusSymbol),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final symbol in focusSymbols)
                        Semantics(
                          button: true,
                          selected: symbol == _symbol,
                          label: symbol,
                          child: GestureDetector(
                            key: ValueKey('focus symbol $symbol'),
                            onTap: () => setState(() => _symbol = symbol),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: symbol == _symbol
                                      ? accent
                                      : const Color(0x00000000),
                                  width: 2,
                                ),
                              ),
                              child: IconTile(
                                symbol: symbol,
                                tint: _focusTint,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SectionHeading(
                    l.focusAllowedApps,
                    description: l.focusAllowedAppsHelp,
                  ),
                  GroupBox(
                    child: appKeys.isEmpty
                        ? EmptyState(l.focusNoApps)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, key) in appKeys.indexed) ...[
                                if (i > 0) const RowSeparator(),
                                ValueRow(
                                  key: ValueKey('focus app $key'),
                                  title: known[key] ?? key,
                                  trailing: AmalfiCheckbox(
                                    value: _apps.contains(key),

                                    onChanged: (on) => setState(() {
                                      if (on) {
                                        _apps.add(key);
                                      } else {
                                        _apps.remove(key);
                                      }
                                    }),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  SectionHeading(
                    l.focusAllowedPeople,
                    description: l.focusAllowedPeopleHelp,
                  ),
                  GroupBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final person in _people) ...[
                          ValueRow(
                            key: ValueKey('focus person $person'),
                            title: person,
                            trailing: AmalfiPushButton(
                              key: ValueKey('remove person $person'),
                              label: l.keyboardSourceRemove,
                              size: AmalfiControlSize.small,
                              onPressed: () =>
                                  setState(() => _people.remove(person)),
                            ),
                          ),
                          const RowSeparator(),
                        ],
                        ValueRow(
                          title: l.focusAllowedPeople,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 180,
                                child: AmalfiTextField(
                                  key: const ValueKey('focus person'),
                                  controller: _person,
                                  placeholder: l.focusPersonPlaceholder,
                                  semanticLabel: l.focusPersonPlaceholder,
                                  onSubmitted: (_) => _addPerson(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AmalfiPushButton(
                                key: const ValueKey('add person'),
                                label: l.addButton,
                                size: AmalfiControlSize.small,
                                onPressed: _addPerson,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.mode != null)
                  AmalfiPushButton(
                    key: const ValueKey('delete focus'),
                    label: l.focusDelete,
                    size: AmalfiControlSize.small,
                    onPressed: () => widget.close(const _Edit.delete()),
                  ),
                const Spacer(),
                AmalfiPushButton(label: l.cancel, onPressed: widget.close),
                const SizedBox(width: 8),
                AmalfiPushButton(
                  key: const ValueKey('focus done'),
                  label: l.done,
                  variant: AmalfiPushButtonVariant.primary,
                  onPressed: _name.text.trim().isEmpty ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
