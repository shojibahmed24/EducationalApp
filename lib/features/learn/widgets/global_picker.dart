// THE picker for the search flow: one widget, every subject.
// Renders the tree the adapters build: a search field on top, a
// drill-down list below, a back row when drilled in. Quick-load
// rules: no network calls of its own (data lives in the
// controller/extras state, loaded once per subject change),
// client-side filtering only, and a lazily built list — so
// opening, drilling, and going back are all instant after the
// first load. Branch taps drill; leaf taps pick.
import 'package:flutter/material.dart';

import '../global_picker_model.dart';
import 'search_flow_field_states.dart';

class GlobalPicker extends StatefulWidget {
  const GlobalPicker({
    super.key,
    required this.treeKey,
    required this.tree,
    required this.s,
    required this.selectedId,
    required this.onPick,
    this.onBranch,
  });
  final String treeKey;
  final GlobalPickerTree tree;
  final Map<String, String> s;
  final String? selectedId;
  final void Function(GlobalPickerPick pick) onPick;

  /// Fired when a branch node is drilled into (stateful adapters,
  /// e.g. English, load the branch's lessons here).
  final void Function(GlobalPickerNode node)? onBranch;

  @override
  State<GlobalPicker> createState() => _GlobalPickerState();
}

class _GlobalPickerState extends State<GlobalPicker> {
  final _filterCtrl = TextEditingController();
  final _path = <GlobalPickerNode>[];
  String _filter = '';

  @override
  void didUpdateWidget(GlobalPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.treeKey != widget.treeKey) {
      _path.clear();
      _filter = '';
      _filterCtrl.clear();
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  List<GlobalPickerNode>? get _current {
    if (_path.isEmpty) return widget.tree.rootNodes;
    return widget.tree.childrenOf(_path.last);
  }

  void _onTap(GlobalPickerNode node) {
    if (node.hasChildren) {
      widget.onBranch?.call(node);
      setState(() => _path.add(node));
      return;
    }
    final pick = node.pick;
    if (pick != null) widget.onPick(pick);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _current;
    final q = _filter.trim().toLowerCase();
    final visible = nodes == null
        ? null
        : q.isEmpty
        ? nodes
        : nodes
              .where(
                (n) =>
                    n.title.toLowerCase().contains(q) ||
                    (n.subtitle?.toLowerCase().contains(q) ?? false),
              )
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _filterCtrl,
          decoration: InputDecoration(
            hintText: widget.s['pickerSearchHint'],
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        if (_path.isNotEmpty)
          InkWell(
            onTap: () => setState(() => _path.removeLast()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _path.last.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.tree.loading && _path.isEmpty)
          SearchFlowLoadingBars(
            label: widget.s['pickerLoading']!,
            semanticsLabel: widget.s['pickerLoading']!,
          )
        else if (nodes == null)
          SearchFlowLoadingBars(
            label: widget.s['pickerLoading']!,
            semanticsLabel: widget.s['pickerLoading']!,
          )
        else if (visible!.isEmpty)
          SearchFlowEmptyCard(
            label: widget.s['pickerLoading']!,
            message: widget.s['pickerEmpty']!,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final node = visible[i];
              final selected = node.id == widget.selectedId;
              final cs = Theme.of(context).colorScheme;
              // Same box as the identity dropdowns (search_flow_
              // field): filled soft card, radius 13, outline
              // border, primary border when selected. Rows are
              // boxes now; drill-down behavior is unchanged.
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _onTap(node),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node.title),
                              if (node.subtitle != null) Text(node.subtitle!),
                            ],
                          ),
                        ),
                        if (node.hasChildren)
                          const Icon(Icons.chevron_right, size: 20)
                        else if (selected)
                          Icon(Icons.check, size: 20, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
