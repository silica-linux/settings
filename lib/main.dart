// Settings, the system settings app of Silica.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'src/app.dart';
import 'src/model/navigation.dart';
import 'src/model/panes.dart';
import 'src/services.dart';
import 'src/style.dart';
import 'src/system/config.dart';
import 'src/system/host.dart';
import 'src/system/system.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  // The toolbar is unified with the window: Ossido draws only the window buttons.
  SilicaWindow.setFullSizeContent(toolbarHeight).ignore();
  // A single-window app: it quits with its window and comes back in the same place
  // (APP-LC; Ossido remembers where the window was).
  SilicaApp.quitWhenLastWindowCloses = true;
  // 832 wide, fixed; the height is free (ST-NAV-01).
  SilicaWindow.setSizeLimits(
    min: const Size(SettingsMetrics.windowWidth, SettingsMetrics.minHeight),
    max: const Size(SettingsMetrics.windowWidth, 100000),
  ).ignore();
  final env = Platform.environment;
  runApp(
    SettingsApp(
      services: Services(
        system: DaemonBackend(),
        config: ConfigStore.forUser(env),
        host: HostReader(env: env),
        env: env,
      ),
      navigation: Navigation(initial: Location(_initialPane(args))),
    ),
  );
}

/// The first argument names a pane (`--dart-arg wifi` on the embedder); Appearance otherwise.
PaneId _initialPane(List<String> args) {
  final name = args.isEmpty ? '' : args.first;
  return PaneId.values.firstWhere(
    (p) => p.name.toLowerCase() == name.toLowerCase(),
    orElse: () => PaneId.appearance,
  );
}
