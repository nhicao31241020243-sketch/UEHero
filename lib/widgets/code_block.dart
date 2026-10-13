import 'package:flutter/material.dart';

class FlashcardCodeBlock extends StatelessWidget {
  const FlashcardCodeBlock({
    required this.code,
    this.language = 'sql',
    super.key,
  });

  final String code;
  final String language;

  static const _background = Color(0xFF11151A);
  static const _teal = Color(0xFF72E0C4);
  static const _lime = Color(0xFFC4EC78);
  static const _blue = Color(0xFF8ABEFF);
  static const _muted = Color(0xFFAAA5B8);

  static final _tokenPattern = RegExp(
    r'''(--[^\n]*|//[^\n]*|'(?:[^']|'')*'|"(?:[^"]|"")*"|\b\d+(?:\.\d+)?\b|\b[A-Za-z_][A-Za-z_0-9]*\b)''',
  );
  static const _keywords = {
    'select',
    'from',
    'where',
    'join',
    'left',
    'right',
    'inner',
    'outer',
    'on',
    'as',
    'group',
    'by',
    'having',
    'order',
    'desc',
    'asc',
    'with',
    'over',
    'partition',
    'and',
    'or',
    'not',
    'null',
    'is',
    'between',
    'case',
    'when',
    'then',
    'else',
    'end',
    'distinct',
    'union',
    'all',
    'calculate',
    'sum',
    'average',
    'count',
    'filter',
    'removefilters',
    'divide',
  };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 14),
    decoration: BoxDecoration(
      color: _background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _teal.withValues(alpha: 0.22)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 5),
          child: Text(
            language.toUpperCase(),
            style: const TextStyle(
              color: _teal,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(13, 4, 13, 13),
          child: SelectableText.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xFFE2E8E6),
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
              ),
              children: _highlight(code),
            ),
          ),
        ),
      ],
    ),
  );

  List<InlineSpan> _highlight(String source) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _tokenPattern.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      final lower = token.toLowerCase();
      final color = token.startsWith('--') || token.startsWith('//')
          ? _muted
          : token.startsWith("'") || token.startsWith('"')
          ? _lime
          : RegExp(r'^\d').hasMatch(token)
          ? _blue
          : _keywords.contains(lower)
          ? _teal
          : null;
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(color: color),
        ),
      );
      cursor = match.end;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }
    return spans;
  }
}
