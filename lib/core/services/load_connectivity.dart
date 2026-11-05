// WiFi gate for prefetch (quick-load plan, Phase 5).
// Prefetch is WiFi-only by default: mobile data is never spent
// on pages the user may never open. Any check failure (no
// plugin, unknown result, exception) means NOT WiFi —
// fail-closed toward saving the user's data.
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isWifiOnlyPrefetchAllowed() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  } catch (_) {
    return false;
  }
}
