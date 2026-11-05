// Shared search-flow field (plan §5): ONE style for every input
// on the search screen — a filled soft card, leading icon, small
// label above, 56px height, accent border on focus, inline error
// text. All colours come from the theme colour scheme (light/dark
// parity, never hardcoded). Two variants: dropdown and text.
import 'package:flutter/material.dart';

/// One dropdown item: the stored value plus its display label.
class SearchFlowDropdownItem<T> {
  const SearchFlowDropdownItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// Card shell owning the FocusNode: the border turns to the accent
/// colour while the inner control has focus.
class _FocusedField extends StatefulWidget {
  const _FocusedField({
    required this.label,
    required this.icon,
    this.errorText,
    required this.builder,
  });
  final String label;
  final IconData icon;
  final String? errorText;
  final Widget Function(FocusNode focus) builder;

  @override
  State<_FocusedField> createState() => _FocusedFieldState();
}

class _FocusedFieldState extends State<_FocusedField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_sync);
  }

  void _sync() {
    if (mounted && _focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_sync);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: text.labelMedium?.copyWith(
                fontFamily: 'HindSiliguri', color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: _focused ? cs.primary : cs.outlineVariant,
                width: _focused ? 2 : 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(widget.icon, size: 22, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: widget.builder(_focus)),
              const SizedBox(width: 12),
            ],
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(widget.errorText!,
                style: text.bodySmall?.copyWith(
                    fontFamily: 'HindSiliguri', color: cs.error)),
          ),
      ],
    );
  }
}

/// Dropdown variant: a borderless DropdownButtonFormField inside
/// the card; the closed state shows a checkmark before the value.
class SearchFlowDropdownField<T> extends StatelessWidget {
  const SearchFlowDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
    this.errorText,
  });
  final String label;
  final IconData icon;
  final T? value;
  final String? hint;
  final List<SearchFlowDropdownItem<T>> items;
  final void Function(T?) onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const labelStyle = TextStyle(fontFamily: 'HindSiliguri');
    return _FocusedField(
      label: label,
      icon: icon,
      errorText: errorText,
      builder: (focus) => DropdownButtonFormField<T>(
        focusNode: focus,
        value: value,
        hint: hint == null ? null : Text(hint!, style: labelStyle),
        decoration: const InputDecoration(
            border: InputBorder.none, contentPadding: EdgeInsets.zero),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
        items: items
            .map((i) => DropdownMenuItem<T>(
                value: i.value,
                child: Text(i.label,
                    overflow: TextOverflow.ellipsis, style: labelStyle)))
            .toList(),
        selectedItemBuilder: (context) => items
            .map((i) => Row(children: [
                  Icon(Icons.check, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(i.label,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle)),
                ]))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// Text variant: borderless TextField with a clear (×) suffix
/// button whenever the field is non-empty.
class SearchFlowTextField extends StatelessWidget {
  const SearchFlowTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    required this.onChanged,
    this.onSubmitted,
    this.errorText,
  });
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;
  final VoidCallback? onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FocusedField(
      label: label,
      icon: icon,
      errorText: errorText,
      builder: (focus) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          style: const TextStyle(fontFamily: 'HindSiliguri'),
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
        ),
      ),
    );
  }
}
