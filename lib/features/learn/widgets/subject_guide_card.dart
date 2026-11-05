// Subject-home guide card. Renders NOTHING (not even an empty
// card) when the subject has no guide counts anywhere: a dead
// card is worse than no card, and counts are never invented.
// Counts come from the cache first, then from the server — the
// server check matters because a textbook-locked subject (e.g.
// class-9 math with no textbook yet) has no chapters-tab path
// to fill the cache, so a cache-only card would hide its guide
// forever on a fresh install.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/guide_bank_service.dart';
import '../../../core/services/resolve_school_class.dart';
import 'digits.dart';

class SubjectGuideCard extends StatelessWidget {
  const SubjectGuideCard({
    super.key,
    required this.subjectId,
    required this.bn,
    required this.s,
    this.schoolClass,
  });
  final String subjectId;
  final bool bn;
  final Map<String, String> s;
  final int? schoolClass; // Explicit class; saved wins in _counts.

  /// Saved class first, then the explicit class, then the
  /// documented last resort 6 in resolveSchoolClass — never a
  /// silent 6 overriding a known class for the index read.
  Future<Map<int, int>?> _counts() async {
    final cls = await resolveSchoolClass(explicit: schoolClass);
    final cached = await guideBankService.subjectChapterCounts(
        subjectId,
        schoolClass: cls);
    if (cached != null && cached.isNotEmpty) return cached;
    // Cache empty: ask the server (guide-native chapters). A
    // null here still means "unknown", and the card stays hidden.
    return guideBankService.fetchGuideChapters(subjectId,
        schoolClass: cls);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, int>?>(
      future: _counts(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final counts = snap.data;
        if (counts == null || counts.isEmpty) {
          return const SizedBox.shrink();
        }
        final total = counts.values.fold<int>(0, (a, b) => a + b);
        if (total <= 0) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(s['guideQuestions']!),
            subtitle: Text(
              '${numStr(total, bn)}${s['questionsSuffix']!} · '
              '${numStr(counts.length, bn)}${s['chaptersSuffix']!}',
            ),
            trailing: const Icon(Icons.chevron_right),
            // Step 7: old /guide-chapters deleted; the new
            // search flow picks the guide source from the
            // lock state (guide when the textbook is locked).
            onTap: () => context.go(
              '/search-flow?subject=$subjectId',
            ),
          ),
        );
      },
    );
  }
}
