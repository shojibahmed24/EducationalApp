// Loading skeleton for guide lists (quick-load Phase 5):
// shimmer cards instead of a bare spinner/text, so the wait
// feels shorter. Uses the shared ShimmerCard (opacity pulse).
import 'package:flutter/material.dart';

import '../../../theme/shimmer_card.dart';

class GuideListLoadingShimmer extends StatelessWidget {
  const GuideListLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const ShimmerCard(lines: 2, height: 96),
    );
  }
}
