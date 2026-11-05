// Shared block renderer (lesson, guide, chat): paragraphs,
// bullets, numbered (Latin AND Bangla digits), headings, tables.
// Pipe rule (B6): ONLY table rows consume pipes — non-table
// lines keep math pipes (|x|); spaced ' | ' and ``` fences drop.
import 'package:flutter/material.dart';

import 'solution_rich_text.dart';

enum _Kind { paragraph, bullets, numbered, heading, table }

class _Block {
  const _Block(this.kind, this.text, this.items, this.headers, this.rows);
  final _Kind kind;
  final String text;
  final List<String> items;
  final List<String> headers;
  final List<List<String>> rows;
}

bool _isSepRow(List<String> cells) =>
    cells.isNotEmpty && cells.every((c) => RegExp(r'^:?-{3,}:?$').hasMatch(c));

List<String> _splitRow(String line) {
  final parts = line.split('|').map((s) => s.trim()).toList();
  if (parts.isNotEmpty && parts.first.isEmpty) parts.removeAt(0);
  if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
  return parts;
}

// Drops only spaced separator pipes; attached math pipes (|x|)
// survive because they never match ' | '.
String _clean(String s) =>
    s.replaceAll(' | ', ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();

bool _isBullet(String t) => RegExp(r'^[-*•]\s+').hasMatch(t);
bool _isNumbered(String t) => RegExp(r'^[0-9০-৯]+[.)]\s+').hasMatch(t);
bool _isFence(String t) => t.startsWith('```');

List<_Block> parseBlocks(String text) {
  final lines = text.split('\n');
  final blocks = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    final t = lines[i].trim();
    if (t.isEmpty || _isFence(t)) {
      i++;
      continue;
    }
    if (t.startsWith('|')) {
      final raw = <String>[];
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        raw.add(lines[i].trim());
        rows.add(_splitRow(lines[i].trim()));
        i++;
      }
      final data = rows.where((r) => !_isSepRow(r)).toList();
      if (data.length >= 2) {
        blocks.add(
          _Block(_Kind.table, '', const [], data.first, data.sublist(1)),
        );
      } else {
        // Not a real table: a lone row with 2+ cells renders as
        // clean joined text; anything else (e.g. |x|) is kept
        // verbatim, pipes included, instead of being split up.
        blocks.add(
          _Block(
            _Kind.paragraph,
            raw
                .map(
                  (r) => _splitRow(r).length >= 2 ? _splitRow(r).join(' ') : r,
                )
                .join(' '),
            const [],
            const [],
            const [],
          ),
        );
      }
      continue;
    }
    if (_isBullet(t) || _isNumbered(t)) {
      final numbered = _isNumbered(t);
      final items = <String>[];
      while (i < lines.length) {
        final lt = lines[i].trim();
        if (lt.isEmpty || _isFence(lt)) break;
        if (numbered ? !_isNumbered(lt) : !_isBullet(lt)) break;
        items.add(
          _clean(lt.replaceFirst(RegExp(r'^[-*•0-9০-৯]+[.)]?\s+'), '')),
        );
        i++;
      }
      blocks.add(
        _Block(
          numbered ? _Kind.numbered : _Kind.bullets,
          '',
          items,
          const [],
          const [],
        ),
      );
      continue;
    }
    final heading = RegExp(r'^#{1,6}\s+(.+)$').firstMatch(t);
    final loneBold = RegExp(r'^\*\*(.+)\*\*$').firstMatch(t);
    if (heading != null || loneBold != null) {
      blocks.add(
        _Block(
          _Kind.heading,
          _clean(heading?.group(1) ?? loneBold!.group(1)!),
          const [],
          const [],
          const [],
        ),
      );
      i++;
      continue;
    }
    final parts = <String>[];
    while (i < lines.length) {
      final lt = lines[i].trim();
      if (lt.isEmpty || _isFence(lt)) break;
      if (lt.startsWith('|') || _isBullet(lt) || _isNumbered(lt)) break;
      if (RegExp(r'^#{1,6}\s+').hasMatch(lt)) break;
      if (RegExp(r'^\*\*(.+)\*\*$').hasMatch(lt)) break;
      parts.add(_clean(lt));
      i++;
    }
    if (parts.isNotEmpty) {
      blocks.add(
        _Block(_Kind.paragraph, parts.join(' '), const [], const [], const []),
      );
    }
  }
  return blocks;
}

class SolutionBlocks extends StatelessWidget {
  const SolutionBlocks({
    super.key,
    required this.text,
    required this.fontSize,
    this.color,
  });
  final String text;
  final double fontSize;
  // Null = resolve from the theme (onSurface): ink in light
  // mode, a light colour in dark mode. Callers that pass an
  // explicit colour (e.g. the final-answer pair) keep it.
  final Color? color;

  Widget _rich(String s, Color c, {double? size}) =>
      SolutionRichText(text: s, fontSize: size ?? fontSize, color: c);

  Widget _table(_Block b, Color c) {
    TableRow row(List<String> cells) {
      return TableRow(
        children: cells
            .map(
              (cell) => Padding(
                padding: const EdgeInsets.all(8),
                child: _rich(cell, c, size: fontSize - 1),
              ),
            )
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: {
          for (var k = 0; k < b.headers.length; k++) k: const FlexColumnWidth(),
        },
        children: [
          row(b.headers.map((h) => h.contains('**') ? h : '**$h**').toList()),
          ...b.rows.map((r) => row(r)),
        ],
      ),
    );
  }

  Widget _list(_Block b, bool numbered, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var k = 0; k < b.items.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    numbered ? '${k + 1}.' : '•',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'HindSiliguri',
                      color: c,
                    ),
                  ),
                ),
                Expanded(child: _rich(b.items[k], c)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final blocks = parseBlocks(text);
    final children = <Widget>[];
    for (var k = 0; k < blocks.length; k++) {
      final b = blocks[k];
      switch (b.kind) {
        case _Kind.paragraph:
          children.add(_rich(b.text, c));
        case _Kind.heading:
          children.add(
            Text(
              b.text,
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: c,
              ),
            ),
          );
        case _Kind.bullets:
          children.add(_list(b, false, c));
        case _Kind.numbered:
          children.add(_list(b, true, c));
        case _Kind.table:
          children.add(_table(b, c));
      }
      if (k < blocks.length - 1) children.add(const SizedBox(height: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
