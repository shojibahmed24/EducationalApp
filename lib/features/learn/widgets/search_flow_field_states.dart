// Search-flow field companions (plan §5): group headings, the
// chapter loading shimmer and the friendly empty-state card.
// Colours come from the theme colour scheme only (light/dark
// parity); Bangla text uses Hind Siliguri.
import 'package:flutter/material.dart';

/// Small group heading above a set of fields.
class SearchFlowGroupLabel extends StatelessWidget {
  const SearchFlowGroupLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontFamily: 'HindSiliguri',
            fontWeight: FontWeight.w700,
            color: cs.primary));
  }
}

/// Small label above a loading/empty field, matching the shared
/// field component's label style.
class SearchFlowFieldLabel extends StatelessWidget {
  const SearchFlowFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFamily: 'HindSiliguri', color: cs.onSurfaceVariant));
  }
}

/// Shimmer skeleton for the loading chapter field: 3 pulsing
/// rounded bars, no new package — a plain opacity animation.
class SearchFlowLoadingBars extends StatefulWidget {
  const SearchFlowLoadingBars(
      {super.key, required this.label, required this.semanticsLabel});
  final String label;
  final String semanticsLabel;

  @override
  State<SearchFlowLoadingBars> createState() => _SearchFlowLoadingBarsState();
}

class _SearchFlowLoadingBarsState extends State<SearchFlowLoadingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFlowFieldLabel(widget.label),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _opacity,
            builder: (context, _) => Opacity(
              opacity: _opacity.value,
              child: Column(
                children: [
                  for (final w in [1.0, 0.75, 0.55])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: w,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty-state card (replaces raw empty text).
class SearchFlowEmptyCard extends StatelessWidget {
  const SearchFlowEmptyCard(
      {super.key, required this.label, required this.message});
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchFlowFieldLabel(label),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(message,
                        style:
                            const TextStyle(fontFamily: 'HindSiliguri'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
