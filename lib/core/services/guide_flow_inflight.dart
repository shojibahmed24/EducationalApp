// In-flight dedupe for search-flow pages (quick-load Phase 5):
// identical concurrent requests share one future instead of
// hitting the server twice. The cleanup uses then() with
// onError and BLOCK bodies: an expression body would return
// the removed (failed) future and the derivative would adopt
// its error as an unhandled async error in tests.
import 'guide_flow_models.dart';

class GuideFlowInflight {
  final _map = <String, Future<GuideFlowPage>>{};

  Future<GuideFlowPage>? existing(String key) => _map[key];

  Future<GuideFlowPage> track(
      String key, Future<GuideFlowPage> fut) {
    _map[key] = fut;
    fut.then<void>((_) {
      _map.remove(key);
    }, onError: (_) {
      _map.remove(key);
    });
    return fut;
  }
}
