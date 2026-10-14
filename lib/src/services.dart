// What the panes reach: the system backend (silica-daemon), the configuration files, the
// machine information and the environment. One [Services] for the window, given to the tree by
// [ServicesScope].

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'accent.dart';
import 'system/config.dart';
import 'system/host.dart';
import 'system/system.dart';
import 'system/tools.dart';
import 'system/tools_host.dart';

/// The size of the sidebar icons (Appearance › Windows).
enum SidebarIconSize { small, medium, large }

/// When scroll bars show (Appearance › Windows).
enum ScrollBarsMode { automatic, whenScrolling, always }

/// The text highlight colour: the accent's, or one of the accents by name.
enum HighlightColor {
  automatic,
  blue,
  purple,
  pink,
  red,
  orange,
  yellow,
  green,
  graphite,
}

T _named<T extends Enum>(List<T> values, String name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

class Services {
  Services({
    required this.system,
    required this.config,
    required this.host,
    required this.env,
    SystemTools? tools,
  }) : info = host.read(),
       tools = tools ?? HostSystemTools(env: env),
       accent = ValueNotifier(
         Accent.parse(config.text('theme', 'accent', fallback: '')),
       ),
       highlight = ValueNotifier(
         _named(
           HighlightColor.values,
           config.text('theme', 'highlight', fallback: ''),
           HighlightColor.automatic,
         ),
       ),
       sidebarIconSize = ValueNotifier(
         _named(
           SidebarIconSize.values,
           config.text('theme', 'sidebarIconSize', fallback: ''),
           SidebarIconSize.medium,
         ),
       ),
       scrollBars = ValueNotifier(
         _named(
           ScrollBarsMode.values,
           config.text('theme', 'scrollBars', fallback: ''),
           ScrollBarsMode.automatic,
         ),
       );

  final SystemBackend system;
  final ConfigStore config;
  final HostReader host;
  final Map<String, String> env;

  /// Read once at the start: the OS, the hardware and the user do not change while the
  /// window is open.
  final HostInfo info;

  /// The system services Settings drives directly (NetworkManager, PipeWire, systemd's
  /// hostnamed, timedated and localed, BlueZ, power profiles, the default apps).
  final SystemTools tools;

  /// The accent the window draws with (theme.json, changed by the Appearance pane).
  final ValueNotifier<Accent> accent;

  /// The text highlight colour (theme.json `highlight`).
  final ValueNotifier<HighlightColor> highlight;

  /// The sidebar icon size (theme.json `sidebarIconSize`).
  final ValueNotifier<SidebarIconSize> sidebarIconSize;

  /// When scroll bars show (theme.json `scrollBars`).
  final ValueNotifier<ScrollBarsMode> scrollBars;

  /// Everything the window's look depends on.
  Listenable get look =>
      Listenable.merge([accent, highlight, sidebarIconSize, scrollBars]);

  void setAccent(Accent value) {
    accent.value = value;
    config.write('theme', 'accent', value.name);
  }

  void setHighlight(HighlightColor value) {
    highlight.value = value;
    config.write('theme', 'highlight', value.name);
  }

  void setSidebarIconSize(SidebarIconSize value) {
    sidebarIconSize.value = value;
    config.write('theme', 'sidebarIconSize', value.name);
  }

  void setScrollBars(ScrollBarsMode value) {
    scrollBars.value = value;
    config.write('theme', 'scrollBars', value.name);
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final Services services;

  static Services of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'no ServicesScope above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope old) => old.services != services;
}

/// Rebuilds with every system state (Wi-Fi, Bluetooth, audio…), from the backend's stream.
class SystemStateBuilder extends StatefulWidget {
  const SystemStateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, SystemState state) builder;

  @override
  State<SystemStateBuilder> createState() => _SystemStateBuilderState();
}

class _SystemStateBuilderState extends State<SystemStateBuilder> {
  SystemState _state = const SystemState();
  StreamSubscription<SystemState>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= ServicesScope.of(context).system.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
