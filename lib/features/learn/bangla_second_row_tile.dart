// Shared row tile for the Bangla 2nd picker screens: question
// text (HindSiliguri) + MCQ options with ক/খ/গ/ঘ letters when
// present. Written/nirmiti rows carry no options, so they show
// title only. Tapping opens the existing answer flow.
import 'package:flutter/material.dart';

import '../../core/models/guide_bank_model.dart';

const _optionLetters = ['ক', 'খ', 'গ', 'ঘ'];

class BanglaSecondRowTile extends StatelessWidget {
  const BanglaSecondRowTile({
    super.key,
    required this.q,
    required this.onTap,
    this.selected = false,
  });
  final GuideBankQuestion q;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.questionText,
                  style: const TextStyle(fontFamily: 'HindSiliguri')),
              if (q.options.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${i < _optionLetters.length ? _optionLetters[i] : '${i + 1}'}. ${q.options[i]}',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
