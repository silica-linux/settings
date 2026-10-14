// The grouped list every pane is built from (ST-NAV-04): groups inset 20 from the content
// edges on the content background, rows separated by 1 pt lines that start at the text,
// navigation rows 48 tall with a chevron, value rows with a trailing switch, pop-up or slider,
// bold 13 pt headings above the groups, header cards. Rows without a backend take no input and
// say so in the group's footer: nothing pretends to work.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../style.dart';
import 'symbol.dart';

/// The scrolling page of a pane.
class PanePage extends StatelessWidget {
  const PanePage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      SettingsMetrics.listInset,
      SettingsMetrics.listInset,
      SettingsMetrics.listInset,
      SettingsMetrics.listInset,
    ),
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: SettingsMetrics.groupSpacing),
        child,
      ],
    ],
  );
}

/// A group: an optional heading, the rows on the group fill, an optional footer.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.heading,
    required this.children,
    this.footer,
    this.unavailable = false,
  });

  final String? heading;
  final List<Widget> children;
  final String? footer;

  /// No backend yet: the rows are drawn disabled and the footer says so.
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final l = AppLocalizations.of(context);
    final footerText = footer ?? (unavailable ? l.notAvailableYet : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading case final heading?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SettingsMetrics.rowTextInset,
              6,
              SettingsMetrics.rowTextInset,
              6,
            ),
            child: Text(
              heading,
              style: settingsText(
                SettingsMetrics.headingSize,
                colors.text,
                weight: FontWeight.w600,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.group,
            borderRadius: BorderRadius.circular(SettingsMetrics.groupRadius),
          ),
          child: _Disabled(
            disabled: unavailable,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.only(left: _textStart(row)),
                      child: Container(height: 1, color: colors.separator),
                    ),
                  row,
                ],
              ],
            ),
          ),
        ),
        if (footerText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SettingsMetrics.rowTextInset,
              6,
              SettingsMetrics.rowTextInset,
              0,
            ),
            child: Text(
              footerText,
              key: unavailable ? const ValueKey('unavailable') : null,
              style: settingsText(11, colors.secondary),
            ),
          ),
      ],
    );
  }

  /// The separator starts where the row's text does.
  static double _textStart(Widget row) =>
      row is NavRow && (row.symbol != null || row.leading != null)
      ? SettingsMetrics.rowTextInset + 32 + 10
      : SettingsMetrics.rowTextInset;
}

/// Unavailable rows: no input, drawn faded.
class _Disabled extends StatelessWidget {
  const _Disabled({required this.disabled, required this.child});
  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => disabled
      ? IgnorePointer(
          child: ExcludeFocus(child: Opacity(opacity: 0.5, child: child)),
        )
      : child;
}

/// A row title with an optional secondary line under it.
class _Titles extends StatelessWidget {
  const _Titles({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: settingsText(13, colors.text),
        ),
        if (subtitle case final subtitle? when subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: settingsText(11, colors.secondary),
          ),
      ],
    );
  }
}

/// A row that opens a sub-pane: icon square, title, optional value, chevron; 48 tall.
class NavRow extends StatefulWidget {
  const NavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.symbol,
    this.tint = const Color(0xFF8E8E93),
    this.leading,
    this.value,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? symbol;
  final Color tint;
  final Widget? leading;
  final String? value;
  final VoidCallback? onTap;

  @override
  State<NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final enabled = widget.onTap != null;
    final symbol = widget.symbol;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        child: Container(
          height: SettingsMetrics.navRowHeight,
          // The pressed row darkens (ST-NAV-05; the shade is provisional).
          color: _pressed
              ? (colors.dark
                    ? const Color(0x14FFFFFF)
                    : const Color(0x0F000000))
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsMetrics.rowTextInset,
          ),
          child: Row(
            children: [
              if (widget.leading case final leading?) ...[
                SizedBox.square(dimension: 32, child: Center(child: leading)),
                const SizedBox(width: 10),
              ] else if (symbol != null) ...[
                IconTile(symbol: symbol, tint: widget.tint, size: 32),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _Titles(title: widget.title, subtitle: widget.subtitle),
              ),
              if (widget.value case final value?)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: Text(value, style: settingsText(13, colors.secondary)),
                ),
              CustomPaint(
                size: const Size(6, 10),
                painter: ChevronPainter(
                  ChevronDirection.right,
                  colors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a title (and a secondary line) and a trailing control.
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.height = SettingsMetrics.valueRowHeight,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: height),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        SettingsMetrics.rowTextInset,
        6,
        SettingsMetrics.trailingInset,
        6,
      ),
      child: Row(
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _Titles(title: title, subtitle: subtitle),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    ),
  );
}

/// A value row with a 36 × 16 switch at the trailing edge.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    subtitle: subtitle,
    trailing: SilicaSwitch(
      value: value,
      onChanged: onChanged,
      size: ControlSize.mini,
      semanticLabel: title,
    ),
  );
}

/// A value row with a pop-up button.
class PopUpRow<T> extends StatelessWidget {
  const PopUpRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final List<PopUpItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    subtitle: subtitle,
    trailing: PopUpButton<T>(
      items: items,
      value: value,
      onChanged: onChanged,
      semanticLabel: title,
    ),
  );
}

/// A value row with a slider between two labels.
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labels,
    this.width = 220,
  });

  final String title;
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final List<String>? labels;
  final double width;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    height: labels == null ? SettingsMetrics.valueRowHeight : 52,
    trailing: SilicaSlider(
      value: value.clamp(min, max),
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      divisions: divisions,
      ticks: divisions != null,
      labels: labels,
      width: width,
      enabled: onChanged != null,
      semanticLabel: title,
    ),
  );
}

/// A row with a push button at the trailing edge.
class ButtonRow extends StatelessWidget {
  const ButtonRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.label,
    this.onPressed,
  });

  final String title;
  final String? subtitle;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    subtitle: subtitle,
    trailing: SilicaButton(label: label, onPressed: onPressed),
  );
}

/// Buttons under a group, at the trailing edge ("Advanced…", "Add…").
class ButtonBar extends StatelessWidget {
  const ButtonBar({super.key, required this.buttons});
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      for (final (i, button) in buttons.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        button,
      ],
    ],
  );
}

/// The card that opens several panes: a large icon, the title and a short description.
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.symbol,
    required this.tint,
    required this.title,
    required this.description,
    this.centered = false,
  });

  final String symbol;
  final Color tint;
  final String title;
  final String description;

  /// The general pane centres the icon above the title and the text.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final texts = Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: settingsText(15, colors.text, weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: settingsText(12, colors.secondary, height: 1.3),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.group,
        borderRadius: BorderRadius.circular(SettingsMetrics.groupRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: centered
            ? Column(
                children: [
                  IconTile(symbol: symbol, tint: tint, size: 56),
                  const SizedBox(height: 10),
                  texts,
                ],
              )
            : Row(
                children: [
                  IconTile(symbol: symbol, tint: tint, size: 48),
                  const SizedBox(width: 14),
                  Expanded(child: texts),
                ],
              ),
      ),
    );
  }
}

/// A centred gray sentence for an empty list ("No VPN configured").
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: settingsText(13, SettingsColors.of(context).secondary),
    ),
  );
}
