// The silica-icons symbols (`symbols/regular/<name>.svg` under the installed icon folders,
// silica_ui's `silicaIconDirs`), tinted; and the coloured rounded square of the sidebar and
// navigation rows. Without the icons installed the symbol is simply absent.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:silica_ui/silica_ui.dart';

import '../services.dart';
import '../style.dart';

final Map<String, File?> _found = {};

File? symbolFile(String name, Map<String, String> env) {
  if (_found.containsKey(name)) return _found[name];
  File? found;
  for (final dir in silicaIconDirs(env)) {
    final file = File('$dir/symbols/regular/$name.svg');
    if (file.existsSync()) {
      found = file;
      break;
    }
  }
  return _found[name] = found;
}

class SettingsSymbol extends StatelessWidget {
  const SettingsSymbol(
    this.name, {
    super.key,
    required this.color,
    this.size = 14,
  });

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = symbolFile(name, ServicesScope.of(context).env);
    return SizedBox.square(
      dimension: size,
      child: file == null
          ? null
          : SvgPicture.file(
              file,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
    );
  }
}

/// A white symbol on a coloured rounded square (sidebar 20 pt; navigation rows and header
/// cards larger).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.symbol,
    required this.tint,
    this.size = SettingsMetrics.iconSize,
    this.radius,
  });

  final String symbol;
  final Color tint;
  final double size;

  /// The corner radius; null: a quarter of the size (5 at 20, 6 at 24).
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    // A flat tile with smooth corners (kit `Tile`: radius 5 at 20 pt, 6 at 24).
    decoration: ShapeDecoration(
      color: tint,
      shape: AmalfiSmoothBorder(
        radius:
            radius ??
            size * SettingsMetrics.iconRadius / SettingsMetrics.iconSize,
      ),
    ),
    child: SettingsSymbol(
      symbol,
      color: const Color(0xFFFFFFFF),
      // 12 in the 20 pt tile of the sidebar, 16 in the 24 pt tile of a row.
      size: size <= 20 ? size * 0.6 : (size >= 56 ? size / 2 : size * 2 / 3),
    ),
  );
}
