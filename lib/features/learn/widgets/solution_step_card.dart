// One numbered step card: number badge, short heading, body,
// optional formula box, optional real table. Marks badges show
// ONLY when [showMarks] is true (printed marks); unprinted
// marks never get an invented badge.
import 'package:flutter/material.dart';

import '../../../core/data/english_redesign.dart';
import '../../../core/models/solution_model.dart';
import '../../../l10n/language_provider.dart';
import 'solution_blocks.dart';
import 'solution_formula_box.dart';

class SolutionStepCard extends StatelessWidget {
  const SolutionStepCard({
    super.key,
    required this.step,
    required this.fontSize,
    required this.showMarks,
    required this.marksWord,
  });
  final SolutionStep step;
  final double fontSize;
  final bool showMarks;
  final String marksWord;

  Widget _table(SolutionTable table, Color textColor) {
    TableRow row(List<String> cells, {bool header = false}) {
      return TableRow(
        children: cells
            .map(
              (c) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    fontFamily: 'HindSiliguri',
                    fontWeight: header ? FontWeight.w600 : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: {
        for (var i = 0; i < table.headers.length; i++)
          i: const FlexColumnWidth(),
      },
      children: [
        row(table.headers, header: true),
        ...table.rows.map((r) => row(r)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // Serial numbers follow the app's locale: Bengali digits in
    // the Bangla UI (like model-test names and sub-numbers),
    // Latin digits in the English UI.
    final bn = languageNotifier.value.languageCode == 'bn';
    final badge = showMarks && step.sectionMarks != null
        ? '${step.sectionLabel != null ? '${step.sectionLabel} · ' : ''}'
            '${bn ? bnDigits(step.sectionMarks!) : step.sectionMarks} $marksWord'
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    bn ? bnDigits(step.n) : '${step.n}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'HindSiliguri',
                      color: onSurface,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Chip(label: Text(badge)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SolutionBlocks(text: step.text, fontSize: fontSize),
            if (step.formulaLatex != null) ...[
              const SizedBox(height: 10),
              SolutionFormulaBox(latex: step.formulaLatex!, fontSize: fontSize),
            ],
            if (step.table != null) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _table(step.table!, onSurface),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
