// What the panes reach: the system backend (silica-daemon), the configuration files, the
// machine information and the environment. One [Services] for the window, given to the tree by
// [ServicesScope].

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'accent.dart';
import 'system/config.dart';
import 'system/host.dart';
import 'system/system.dart';

class Services {
  Services({
    required this.system,
    required this.config,
    required this.host,
    required this.env,
  }) : info = host.read(),
       accent = ValueNotifier(
         Accent.parse(config.text('theme', 'accent', fallback: '')),
       );

  final SystemBackend system;
  final ConfigStore config;
  final HostReader host;
  final Map<String, String> env;

  /// Read once at the start: the OS, the hardware and the user do not change while the
  /// window is open.
  final HostInfo info;

  /// The accent the window draws with (theme.json, changed by the Appearance pane).
  final ValueNotifier<Accent> accent;

  void setAccent(Accent value) {
    accent.value = value;
    config.write('theme', 'accent', value.name);
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
