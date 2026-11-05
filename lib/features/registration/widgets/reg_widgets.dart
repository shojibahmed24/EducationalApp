// Shared small widgets for registration steps. All under 250 lines
// combined here so steps stay small. Warm Paper style via AppTheme only.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/language_provider.dart';
import '../../../theme/app_theme.dart';

// Mixin for registration step states: rebuilds the step whenever the
// app language changes, so tapping the language toggle in RegScaffold
// re-resolves the step's strings AT ONCE instead of only on the next
// navigation. Other screens use ValueListenableBuilder for the same
// purpose; steps are StatefulWidgets, so a listener is the equivalent.
// Steps with their own dispose() must keep calling super.dispose(),
// which chains through this mixin and removes the listener.
mixin RegLangMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }
}

// Phase 17 (L6): Stateful so a password field can offer a
// show/hide eye toggle. Other fields are unaffected: without
// showObscureToggle there is no suffix icon and behaviour is as before.
class RegTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final bool showObscureToggle;
  final int? maxLength;

  const RegTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.showObscureToggle = false,
    this.maxLength,
  });

  @override
  State<RegTextField> createState() => _RegTextFieldState();
}

class _RegTextFieldState extends State<RegTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Card(
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: _obscured,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              counterText: '',
              suffixIcon: widget.showObscureToggle
                  ? IconButton(
                      icon: Icon(_obscured
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.08)
          : AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OtpField extends StatelessWidget {
  final List<TextEditingController> controllers;
  const OtpField({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    // H9: no fixed box width. Each box takes an equal share of the
    // available width (capped on wide screens), so the row can never
    // overflow on 320-360px phones or at larger font scales. The
    // 12px gaps are fixed; only the boxes flex.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 3) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
