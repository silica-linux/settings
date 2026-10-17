// The root of Settings: the language from the system (English source, Italian translation),
// the active / inactive state from Ossido (`flutter/lifecycle`), the accent chosen in
// Appearance, and an overlay for pop-up menus and sheets.

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:silica_ui/silica_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'model/navigation.dart';
import 'services.dart';
import 'startup.dart';
import 'ui/window.dart';

/// The system languages resolved against ours, English when none matches.
Locale resolveLocale(List<Locale> preferred) =>
    basicLocaleListResolution(preferred, AppLocalizations.supportedLocales);

class SettingsApp extends StatefulWidget {
  const SettingsApp({
    super.key,
    required this.services,
    required this.navigation,
    this.locale,
  });

  final Services services;
  final Navigation navigation;

  /// A fixed language (tests); null follows the system.
  final Locale? locale;

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> with WidgetsBindingObserver {
  late Locale _locale =
      widget.locale ?? resolveLocale(PlatformDispatcher.instance.locales);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startupMark('app state created');
    // The window first; the machine information once it is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startupMark('first frame');
      widget.services.loadHostInfo();
    });
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (widget.locale != null || locales == null) return;
    setState(() => _locale = resolveLocale(locales));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations(
    locale: _locale,
    delegates: const [
      AppLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: ServicesScope(
        services: widget.services,
        child: HostInfoScope(
          info: widget.services.hostInfo,
          child: WindowActiveScope.follow(
            child: _Scopes(
              services: widget.services,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => ListenableBuilder(
                      listenable: widget.navigation,
                      builder: (context, _) =>
                          SettingsWindow(navigation: widget.navigation),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The toolbar's active state and the accent, which follow the window and Appearance.
class _Scopes extends StatelessWidget {
  const _Scopes({required this.services, required this.child});
  final Services services;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    return ListenableBuilder(
      listenable: services.look,
      builder: (context, _) => ToolbarScope(
        active: WindowActiveScope.of(context),
        child: ControlAccent(
          color: services.accent.value.fill(dark: dark),
          // The look chosen here follows live (silica_ui's SystemLookScope): scroll bars
          // (always keeps the track), the click in the track, highlight, icon style.
          child: SystemLookScope(
            child: ScrollConfiguration(
              behavior: const SilicaScrollBehavior(),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
