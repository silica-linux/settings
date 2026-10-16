// The grouped list every pane is built from (kit `Apps/Settings/Row/*`): groups inset 20 from
// the content's sides, 16 under the toolbar and 12 apart, radius 12, rows separated by 1 pt
// lines inset 12 on both sides; navigation rows 52 tall with a 24 pt tile and a chevron; value
// rows 44 tall with a trailing switch, pop-up or slider; Headline headings; header cards. Rows without a backend take no input and their group's footer says why, with
// the issue that tracks the missing piece: nothing pretends to work.

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../style.dart';
import 'symbol.dart';

/// Marks the first child of a page: its heading has no space above.
class _FirstOnPage extends InheritedWidget {
  const _FirstOnPage({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FirstOnPage>() != null;

  @override
  bool updateShouldNotify(_FirstOnPage old) => false;
}

/// The scrolling page of a pane.
class PanePage extends StatelessWidget {
  const PanePage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      SettingsMetrics.listInset,
      SettingsMetrics.pageTop,
      SettingsMetrics.listInset,
      SettingsMetrics.listInset,
    ),
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: SettingsMetrics.groupSpacing),
        if (i == 0) _FirstOnPage(child: child) else child,
      ],
    ],
  );
}

/// A section heading (bold 13) with an optional description under it.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.description});

  final String text;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        _FirstOnPage.of(context) ? 0 : SettingsMetrics.headingAbove,
        0,
        SettingsMetrics.headingBelow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AmalfiType.headline(color: colors.text)),
          if (description case final description?)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: AmalfiType.callout(color: colors.secondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// The rounded fill of a group.
class GroupBox extends StatelessWidget {
  const GroupBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: SettingsColors.of(context).group,
      shape: AmalfiSmoothBorder(radius: SettingsMetrics.groupRadius),
    ),
    child: child,
  );
}

/// The 1 pt line between rows, inset 10 on both sides.
class RowSeparator extends StatelessWidget {
  const RowSeparator({super.key, this.indent = 0});

  /// Extra inset at the leading edge (rows nested under another row).
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: SettingsMetrics.separatorInset + indent,
      right: SettingsMetrics.separatorInset,
    ),
    child: Container(height: 1, color: SettingsColors.of(context).separator),
  );
}

/// A group: an optional heading, the rows on the group fill, an optional footer.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.heading,
    this.description,
    required this.children,
    this.footer,
    this.unavailable = false,
    this.issue,
  });

  final String? heading;

  /// A line of text under the heading.
  final String? description;
  final List<Widget> children;
  final String? footer;

  /// No backend yet: the rows are drawn disabled and the footer says so.
  final bool unavailable;

  /// The silica-os/settings issue that tracks the missing backend (for developers; never shown).
  final int? issue;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final l = AppLocalizations.of(context);
    final missing = unavailable ? l.notAvailableYet : null;
    final footerText = [?footer, ?missing].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading case final heading?)
          SectionHeading(heading, description: description),
        GroupBox(
          child: _Disabled(
            disabled: unavailable,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in children.indexed) ...[
                  if (i > 0) RowSeparator(indent: _indentOf(row)),
                  row,
                ],
              ],
            ),
          ),
        ),
        if (footerText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SettingsMetrics.rowTextInset,
              8,
              SettingsMetrics.rowTextInset,
              0,
            ),
            child: Text(
              footerText,
              key: unavailable ? const ValueKey('unavailable') : null,
              style: AmalfiType.caption(color: colors.disabled),
            ),
          ),
      ],
    );
  }

  static double _indentOf(Widget row) => switch (row) {
    ValueRow(:final indent) => indent,
    SwitchRow(:final indent) => indent,
    Unavailable(:final child) => _indentOf(child),
    _ => 0,
  };
}

/// Unavailable rows: no input, drawn faded.
class _Disabled extends StatelessWidget {
  const _Disabled({required this.disabled, required this.child});
  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => disabled
      ? IgnorePointer(
          child: ExcludeFocus(child: Opacity(opacity: 0.45, child: child)),
        )
      : child;
}

/// A row title with an optional secondary line under it.
class RowTitles extends StatelessWidget {
  const RowTitles({super.key, required this.title, this.subtitle, this.weight});
  final String title;
  final String? subtitle;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AmalfiType.body(
            color: colors.text,
          ).copyWith(fontWeight: weight),
        ),
        if (subtitle case final subtitle? when subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AmalfiType.callout(color: colors.secondary),
            ),
          ),
      ],
    );
  }
}

/// The trailing chevron of navigation rows.
class RowChevron extends StatelessWidget {
  const RowChevron({super.key});

  @override
  Widget build(BuildContext context) => AmalfiGlyph(
    AmalfiGlyphs.chevronRight,
    size: 12,
    color: SettingsColors.of(context).disabled,
  );
}

/// A row that opens a sub-pane: 24 pt icon square, title, optional value, chevron; 48 tall.
class NavRow extends StatefulWidget {
  const NavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.symbol,
    this.tint = const Color(0xFF9A9EA6),
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
    final hasIcon = widget.leading != null || symbol != null;
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
          constraints: BoxConstraints(
            minHeight: hasIcon || widget.subtitle != null
                ? SettingsMetrics.navRowHeight
                : SettingsMetrics.valueRowHeight,
          ),
          // The pressed row darkens (ST-NAV-05; the shade is provisional).
          color: _pressed
              ? AmalfiTheme.of(context).colors.statePressOverlay
              : null,
          padding: EdgeInsets.only(
            left: hasIcon
                ? SettingsMetrics.navIconLeft
                : SettingsMetrics.rowTextInset,
            right: 12,
          ),
          child: Row(
            children: [
              if (widget.leading case final leading?) ...[
                SizedBox.square(
                  dimension: SettingsMetrics.navIconSize,
                  child: Center(child: leading),
                ),
                const SizedBox(width: SettingsMetrics.navIconGap),
              ] else if (symbol != null) ...[
                IconTile(
                  symbol: symbol,
                  tint: widget.tint,
                  size: SettingsMetrics.navIconSize,
                ),
                const SizedBox(width: SettingsMetrics.navIconGap),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: RowTitles(
                    title: widget.title,
                    subtitle: widget.subtitle,
                  ),
                ),
              ),
              if (widget.value case final value?)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Text(
                    value,
                    style: AmalfiType.body(color: colors.secondary),
                  ),
                ),
              const RowChevron(),
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
    this.indent = 0,
    this.alignTop = false,
    this.weight,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double height;

  /// Rows nested under another (the conditions of a choice) start further in.
  final double indent;

  /// Tall trailing controls (the appearance previews) keep the title at the top.
  final bool alignTop;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: height),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        SettingsMetrics.rowTextInset + indent,
        alignTop ? 12 : 8,
        SettingsMetrics.trailingInset,
        8,
      ),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (leading case final leading?) ...[
            leading,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: RowTitles(title: title, subtitle: subtitle, weight: weight),
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
    this.indent = 0,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double indent;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    subtitle: subtitle,
    indent: indent,
    trailing: AmalfiSwitch(
      value: value,
      onChanged: onChanged,
      semanticLabel: title,
    ),
  );
}

/// A value row with the form pop-up.
class PopUpRow<T> extends StatelessWidget {
  const PopUpRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.value,
    this.onChanged,
    this.leading,
    this.indent = 0,
  });

  final String title;
  final String? subtitle;
  final List<PopUpItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;

  /// Drawn before the value (a colour swatch).
  final Widget? leading;
  final double indent;

  @override
  Widget build(BuildContext context) => ValueRow(
    title: title,
    subtitle: subtitle,
    indent: indent,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading case final leading?) ...[leading, const SizedBox(width: 8)],
        SettingsPopUp<T>(
          items: items,
          value: value,
          onChanged: onChanged,
          semanticLabel: title,
        ),
      ],
    ),
  );
}

/// The small pop-up button of a settings row (kit `Buttons/Pop-up/Small`, 108 wide, wider when
/// a label needs it).
class SettingsPopUp<T> extends StatelessWidget {
  const SettingsPopUp({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.placeholder = '',
  });

  final List<PopUpItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;
  final String placeholder;

  @override
  Widget build(BuildContext context) => AmalfiPopUpButton<T>(
    items: [
      for (final item in items)
        AmalfiPopUpItem<T>(
          value: item.value,
          label: item.label,
          enabled: item.enabled,
        ),
    ],
    value: value,
    onChanged: onChanged,
    size: AmalfiControlSize.small,
    width: popUpWidth(items.map((i) => i.label)),
    placeholder: placeholder,
    semanticLabel: semanticLabel,
  );
}

/// The width of a small pop-up for [labels]: the kit's 108, wider when a label needs it
/// (8 before, 4 after the chevron, 4 between, the 14 pt chevron).
double popUpWidth(Iterable<String> labels) {
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: AmalfiPopUpButtonMetrics.labelStyle(
          AmalfiControlSize.small,
          const Color(0xFF000000),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return (widest + 8 + 4 + 4 + 14).ceilToDouble().clamp(108, 280);
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
    this.width = 200,
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
    height: labels == null ? SettingsMetrics.valueRowHeight : 56,
    trailing: LabelledSlider(
      value: value,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      divisions: divisions,
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
    trailing: AmalfiPushButton(
      label: label,
      onPressed: onPressed,
      size: AmalfiControlSize.small,
    ),
  );
}

/// Buttons under a group, at the trailing edge ("Advanced…", "Add…").
class ButtonBar extends StatelessWidget {
  const ButtonBar({super.key, required this.buttons, this.leading});
  final List<Widget> buttons;
  final List<Widget>? leading;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ...?leading,
      const Spacer(),
      for (final (i, button) in buttons.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        button,
      ],
    ],
  );
}

/// The card that opens several panes: an icon, the title and a short description; the
/// general pane centres a large icon above a large title (ST-NAV-04, INV-C1).
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.symbol,
    required this.tint,
    required this.title,
    required this.description,
    this.centered = false,
    this.trailing,
  });

  final String symbol;
  final Color tint;
  final String title;
  final String description;

  /// The general pane centres the icon above the title and the text.
  final bool centered;

  /// A control at the trailing edge (the Wi-Fi and Bluetooth switches).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final theme = AmalfiTheme.of(context).colors;
    if (centered) {
      // The pane's own header (kit `General tile`, `General title`, `General text`): a 64 pt
      // tile, Title 2 and a Callout text under it, no group around them.
      return Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          children: [
            IconTile(symbol: symbol, tint: tint, size: 64, radius: 16),
            const SizedBox(height: 19),
            Text(title, style: AmalfiType.title2(color: colors.text)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 412),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AmalfiType.callout(color: theme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return GroupBox(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(symbol: symbol, tint: tint, size: 56, radius: 14),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AmalfiType.title3(color: colors.text)),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AmalfiType.callout(color: colors.secondary),
                  ),
                ],
              ),
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
      style: AmalfiType.body(color: SettingsColors.of(context).secondary),
    ),
  );
}

/// A secondary-text value at the trailing edge of a row.
class RowValue extends StatelessWidget {
  const RowValue(this.text, {super.key, this.selectable = false});
  final String text;
  final bool selectable;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 300),
    child: Text(
      text,
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AmalfiType.body(color: SettingsColors.of(context).secondary),
    ),
  );
}

/// A short message under a control that failed (a refused password, a change that needs an
/// administrator).
class ErrorLine extends StatelessWidget {
  const ErrorLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SettingsMetrics.rowTextInset,
      8,
      SettingsMetrics.rowTextInset,
      0,
    ),
    child: Text(
      text,
      key: const ValueKey('error'),
      style: AmalfiType.caption(
        color: AmalfiTheme.of(context).colors.paletteTerracotta,
      ),
    ),
  );
}

/// One row of a working group that waits for a backend: no input, faded; the group's footer
/// names the issue.
class Unavailable extends StatelessWidget {
  const Unavailable({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _Disabled(disabled: true, child: child);
}

/// A slider with optional tick labels under it (kit `Sliders/Horizontal/Ticks`); [width]
/// 200 by default (kit `Row/Slider`).
class LabelledSlider extends StatelessWidget {
  /// [key] goes to the slider itself, so a finder by key reaches the control.
  const LabelledSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.ticks,
    this.labels,
    this.width = 200,
    this.enabled = true,
    this.semanticLabel,
  }) : _sliderKey = key;

  final Key? _sliderKey;
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;

  /// Whether to draw tick marks; null: when there are [divisions].
  final bool? ticks;
  final List<String>? labels;
  final double width;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context);
    final slider = SizedBox(
      width: width,
      child: AmalfiSlider(
        key: _sliderKey,
        value: value.clamp(min, max),
        onChanged: enabled ? onChanged : null,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
        tickMarks: ticks ?? divisions != null,
        semanticLabel: semanticLabel,
      ),
    );
    final labels = this.labels;
    if (labels == null) return slider;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        slider,
        SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in labels)
                Text(label, style: AmalfiType.caption(color: colors.secondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Radio buttons stacked, one per option (kit `Toggles/Radio`).
class SettingsRadioGroup<T> extends StatelessWidget {
  const SettingsRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.spacing = 8,
  });

  final List<RadioOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: spacing,
    children: [
      for (final option in options)
        AmalfiRadio(
          selected: option.value == value,
          label: option.label,
          onSelected: onChanged == null || !option.enabled
              ? null
              : () => onChanged!(option.value),
        ),
    ],
  );
}

/// A row with a radio button and its label (kit `Row/Radio Off`, `Row/Radio On`): 48 tall,
/// the radio at x 12, the label at x 40.
class RadioRow extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: SettingsMetrics.checkRowHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SettingsMetrics.rowTextInset,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AmalfiRadio(
          selected: selected,
          label: label,
          onSelected: onSelected,
        ),
      ),
    ),
  );
}
