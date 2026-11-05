// Shared result shapes for the new search-flow guide list.
// Split out so the server path (guide_flow_list_service) and the
// old-server client scan (guide_flow_client_scan) share them
// without a circular import.
import '../models/guide_bank_model.dart';

enum GuideFlowMode { serverFiltered, clientFiltered, unavailable, filterPending }

enum GuideFlowJumpOutcome { found, notFound, filterPending, unavailable }

class GuideFlowPage {
  const GuideFlowPage({
    required this.rows,
    required this.total,
    required this.hasMore,
    required this.mode,
    required this.nextScanOffset,
  });
  final List<GuideBankQuestion> rows;

  /// Exact filtered total on serverFiltered pages; null otherwise
  /// (clientFiltered totals are unknowable without a full scan).
  final int? total;
  final bool hasMore;
  final GuideFlowMode mode;

  /// Server offset to resume a clientFiltered scan from.
  final int nextScanOffset;
}

class GuideFlowJump {
  const GuideFlowJump({required this.question, required this.outcome});
  final GuideBankQuestion? question;
  final GuideFlowJumpOutcome outcome;
}

typedef GuideFlowPost = Future<Map<String, dynamic>?> Function(
    Map<String, dynamic> body, {String? endpoint});
