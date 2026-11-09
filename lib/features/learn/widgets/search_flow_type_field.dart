// Question-type dropdown with exact counts (guide mode). Once a
// chapter (and lesson) is chosen, each type shows how many
// questions it has: "সৃজনশীল · ৫০". Counts load lazily, only for
// the current selection, via guideFlowCountService; an unknown
// count (old server, offline) shows the plain label, never a
// guess. A zero stays visible as "০" so missing data is obvious.
import 'package:flutter/material.dart';

import '../../../core/services/guide_flow_count_service.dart';
import '../search_flow_types.dart';
import 'digits.dart';
import 'search_flow_field.dart';

class SearchFlowTypeField extends StatefulWidget {
  const SearchFlowTypeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.s,
    required this.bn,
    required this.guide,
    required this.subject,
    required this.schoolClass,
    required this.chapter,
    required this.lesson,
    this.service,
  });

  final SearchFlowType? value;
  final void Function(SearchFlowType?) onChanged;
  final Map<String, String> s;
  final bool bn;
  final bool guide;
  final String subject;
  final int schoolClass;
  final int? chapter;
  final String? lesson;
  final GuideFlowCountService? service;

  @override
  State<SearchFlowTypeField> createState() => _SearchFlowTypeFieldState();
}

class _SearchFlowTypeFieldState extends State<SearchFlowTypeField> {
  Map<SearchFlowType, int?> _counts = const {};
  int _token = 0;

  GuideFlowCountService get _svc => widget.service ?? guideFlowCountService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SearchFlowTypeField old) {
    super.didUpdateWidget(old);
    if (old.guide != widget.guide ||
        old.subject != widget.subject ||
        old.schoolClass != widget.schoolClass ||
        old.chapter != widget.chapter ||
        old.lesson != widget.lesson) {
      _load();
    }
  }

  Future<void> _load() async {
    final token = ++_token;
    final chapter = widget.chapter;
    if (!widget.guide || chapter == null) {
      if (_counts.isNotEmpty) setState(() => _counts = const {});
      return;
    }
    if (_counts.isNotEmpty) setState(() => _counts = const {});
    final out = await _svc.countAll(
      subject: widget.subject,
      schoolClass: widget.schoolClass,
      chapter: chapter,
      lesson: widget.lesson,
    );
    if (!mounted || token != _token) return; // a newer pick won
    setState(() => _counts = out);
  }

  String _label(SearchFlowType t) {
    final base = searchFlowTypeLabel(t, widget.s);
    final n = _counts[t];
    return n == null ? base : '$base · ${numStr(n, widget.bn)}';
  }

  @override
  Widget build(BuildContext context) {
    return SearchFlowDropdownField<SearchFlowType>(
      label: widget.s['typeLabel']!,
      icon: Icons.category,
      value: widget.value,
      items: [
        for (final t in SearchFlowType.values)
          SearchFlowDropdownItem(value: t, label: _label(t)),
      ],
      onChanged: widget.onChanged,
    );
  }
}
