// Debug-only load timing (quick-load plan, Phase 0).
// No-op in release builds (kDebugMode gate): timing logs must
// never cost anything on a user's phone. Callers create one
// timer per fetch, lap() at milestones, done() at the end.
import 'package:flutter/foundation.dart';

class LoadTimer {
  LoadTimer(this.label) : _sw = Stopwatch()..start();
  final String label;
  final Stopwatch _sw;

  void lap(String step) {
    if (kDebugMode) {
      debugPrint('LOAD [$label] $step: ${_sw.elapsedMilliseconds}ms');
    }
  }

  void done() => lap('done');
}
