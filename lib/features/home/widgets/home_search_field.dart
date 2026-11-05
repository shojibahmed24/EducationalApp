// Home search field (Phase 16, M1). The typed text is NOT discarded:
// submitting goes to /search with it as the ?q= query parameter, and
// the Search screen shows it. Empty text still opens plain /search.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeSearchField extends StatefulWidget {
  const HomeSearchField({super.key, required this.hint});
  final String? hint;
  @override
  State<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<HomeSearchField> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final q = value.trim();
    if (q.isEmpty) {
      context.go('/search');
    } else {
      context.go('/search?q=${Uri.encodeComponent(q)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _submit,
    );
  }
}
