// One translated text field for the English reader.
// When translation is OFF it is just the original text. When ON
// it shows the Bangla translation as soon as it arrives — and
// the ORIGINAL English meanwhile, never a spinner and never a
// blank area (a slow model must not hide content the student
// could already read). On failure it keeps the original and
// adds a short note plus a retry button; retry re-requests only
// that field. Each field translates on its own, so options stay
// separate options and poem line breaks survive.
import 'package:flutter/material.dart';

import '../../../core/services/english_translation_service.dart';

class EnglishTranslatedText extends StatefulWidget {
  const EnglishTranslatedText({
    super.key,
    required this.text,
    required this.translate,
    required this.service,
    required this.failedNote,
    required this.retryLabel,
    this.style,
  });
  final String text;
  final bool translate;
  final EnglishTranslationService service;
  final String failedNote;
  final String retryLabel;
  final TextStyle? style;

  @override
  State<EnglishTranslatedText> createState() =>
      _EnglishTranslatedTextState();
}

class _EnglishTranslatedTextState extends State<EnglishTranslatedText> {
  String? _translated;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.translate) _requestTranslation();
  }

  @override
  void didUpdateWidget(EnglishTranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.translate != widget.translate) {
      _translated = null;
      _failed = false;
      if (widget.translate) _requestTranslation();
    }
  }

  Future<void> _requestTranslation() async {
    final id = ++_request;
    final out = await widget.service.translate(widget.text);
    if (!mounted || id != _request) return;
    setState(() {
      if (out == null) {
        _failed = true;
      } else {
        _translated = out;
      }
    });
  }

  void _retry() {
    setState(() => _failed = false);
    _requestTranslation();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.translate || _translated != null) {
      return Text(_translated ?? widget.text, style: widget.style);
    }
    if (_failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.failedNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: _retry,
                child: Text(widget.retryLabel),
              ),
            ],
          ),
        ],
      );
    }
    // Still translating: the original stays readable meanwhile.
    return Text(widget.text, style: widget.style);
  }
}
