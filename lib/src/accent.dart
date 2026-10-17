// The system accent colours (CT-CL-01, measured in sRGB): the plain colour (default button,
// progress) and the control fill (switches, checkboxes, selected segments, sliders), light and
// dark. "Multicolour" is the default and draws like blue in every control.

import 'dart:ui' show Color;

enum Accent {
  multicolour(
    Color(0xFF007AFF),
    Color(0xFF0077F9),
    Color(0xFF007AFF),
    Color(0xFF0D7DFF),
  ),
  blue(
    Color(0xFF007AFF),
    Color(0xFF0077F9),
    Color(0xFF007AFF),
    Color(0xFF0D7DFF),
  ),
  purple(
    Color(0xFF953D96),
    Color(0xFF913B92),
    Color(0xFFA650A7),
    Color(0xFFA755A9),
  ),
  pink(
    Color(0xFFF74F9F),
    Color(0xFFF04E9A),
    Color(0xFFF74F9F),
    Color(0xFFF854A1),
  ),
  red(
    Color(0xFFE0393E),
    Color(0xFFDB373D),
    Color(0xFFFF5257),
    Color(0xFFFF565B),
  ),
  // `Palette/Arancia` (silica-ui#97), not Limone and not the measured reference orange.
  orange(
    Color(0xFFF98A17),
    Color(0xFFF98A17),
    Color(0xFFFF9F40),
    Color(0xFFFF9F40),
  ),
  yellow(
    Color(0xFFFFC727),
    Color(0xFFF9C225),
    Color(0xFFFFC601),
    Color(0xFFFFC811),
  ),
  green(
    Color(0xFF62BA46),
    Color(0xFF5FB644),
    Color(0xFF62BA46),
    Color(0xFF66BC4A),
  ),
  graphite(
    Color(0xFF989898),
    Color(0xFF949494),
    Color(0xFF8C8C8C),
    Color(0xFF8F8F8F),
  );

  const Accent(this.plainLight, this.fillLight, this.plainDark, this.fillDark);

  final Color plainLight;
  final Color fillLight;
  final Color plainDark;
  final Color fillDark;

  Color plain({required bool dark}) => dark ? plainDark : plainLight;
  Color fill({required bool dark}) => dark ? fillDark : fillLight;

  /// The accent saved under `accent` in theme.json; multicolour when unknown.
  static Accent parse(String? name) => Accent.values.firstWhere(
    (a) => a.name == name,
    orElse: () => Accent.multicolour,
  );
}
