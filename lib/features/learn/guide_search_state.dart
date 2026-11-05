// Debounced whole-guide search state for the guide bank
// screen. The screen owns one instance, sets onChanged to its
// setState, and calls queryChanged on every search keystroke.
// Behaviour: blank query clears server state synchronously
// (local chapter filtering resumes, no server call); a typed
// query waits out the debounce, then calls the server once —
// stale (superseded) results are dropped by sequence number,
// never shown. A failed search leaves serverRows null and sets
// serverFailed, so the UI falls back to local filtering with
// an honest note instead of a silent empty list.
import 'dart:async';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/guide_search_service.dart';

typedef GuideSearchFn = Future<List<GuideBankQuestion>?> Function({
  required String subject,
  required int schoolClass,
  required String query,
});

class GuideSearchState {
  GuideSearchState({
    this.search = searchGuide,
    this.debounce = const Duration(milliseconds: 500),
  });

  final GuideSearchFn search;
  final Duration debounce;

  /// Null = no server search active (blank query, or failed).
  List<GuideBankQuestion>? serverRows;
  bool serverFailed = false;
  bool serverSearching = false;

  /// Called on every state change; the screen wires setState.
  void Function() onChanged = () {};

  Timer? _timer;
  int _seq = 0;

  void queryChanged(
    String query, {
    required String subject,
    required int schoolClass,
  }) {
    _timer?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      serverRows = null;
      serverFailed = false;
      serverSearching = false;
      onChanged();
      return;
    }
    serverSearching = true;
    serverFailed = false;
    onChanged();
    _timer = Timer(debounce, () async {
      final seq = ++_seq;
      final rows = await search(
          subject: subject, schoolClass: schoolClass, query: q);
      if (seq != _seq) return; // Superseded by a newer query.
      serverSearching = false;
      if (rows == null) {
        serverFailed = true;
        serverRows = null;
      } else {
        serverFailed = false;
        serverRows = rows;
      }
      onChanged();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
