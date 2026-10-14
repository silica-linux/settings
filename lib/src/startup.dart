// A timestamped log of the start (`SETTINGS_STARTUP_LOG=1`): how long each step takes from
// `main`, so a slow start shows where the time goes. Silent otherwise.

import 'dart:io';

import 'package:flutter/foundation.dart';

final Stopwatch _clock = Stopwatch();

/// The marks so far, `(milliseconds since main, what)`; tests read them.
final List<(int, String)> startupMarks = [];

bool startupLogEnabled = Platform.environment['SETTINGS_STARTUP_LOG'] == '1';

/// Starts the clock (first line of `main`).
void startupBegin() {
  startupMarks.clear();
  _clock
    ..reset()
    ..start();
  startupMark('main');
}

void startupMark(String what) {
  final ms = _clock.elapsedMicroseconds ~/ 1000;
  startupMarks.add((ms, what));
  if (startupLogEnabled) debugPrint('[settings +${ms}ms] $what');
}
