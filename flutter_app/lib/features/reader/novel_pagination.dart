import 'dart:math';

import 'package:flutter/painting.dart';

/// A page keeps the exact text slices produced by layout, including spaces and
/// complete Unicode characters. Continuations do not add paragraph indentation.
class NovelPageText {
  final String text;
  final bool title;
  final double bottomPadding;

  const NovelPageText(this.text, {this.title = false, this.bottomPadding = 16});
}

class NovelTextPage {
  final List<NovelPageText> blocks;
  final double contentHeight;

  NovelTextPage(List<NovelPageText> blocks, this.contentHeight)
      : blocks = List.unmodifiable(blocks);
}

/// Measure with the same width, styles and accessibility scale as the reader.
/// Split at visual line boundaries so a long paragraph cannot overflow a page.
List<NovelTextPage> paginateNovelText({
  required String title,
  required List<String> paragraphs,
  required Size size,
  required TextStyle bodyStyle,
  required TextStyle titleStyle,
  required TextScaler textScaler,
  required TextDirection textDirection,
  required double footerHeight,
  Locale? locale,
}) {
  final height = max(1.0, size.height - 1); // Leave room for fractional pixels.
  final width = max(1.0, size.width);
  final source = <NovelPageText>[
    if (title.isNotEmpty) NovelPageText(title, title: true, bottomPadding: 24),
    for (final paragraph in paragraphs)
      NovelPageText('\u3000\u3000${paragraph.trim()}'),
  ];
  final pages = <NovelTextPage>[];
  var blocks = <NovelPageText>[];
  var used = 0.0;

  void finishPage() {
    pages.add(NovelTextPage(blocks, used));
    blocks = [];
    used = 0;
  }

  for (var index = 0; index < source.length; index++) {
    final block = source[index];
    var remaining = block.text;
    while (remaining.isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
            text: remaining, style: block.title ? titleStyle : bodyStyle),
        textDirection: textDirection,
        textAlign: block.title ? TextAlign.center : TextAlign.start,
        textScaler: textScaler,
        locale: locale,
        textHeightBehavior: const TextHeightBehavior(),
      )..layout(maxWidth: width);
      try {
        final available = height - used;
        final lastBlock = index == source.length - 1;
        final fullHeight = painter.height + block.bottomPadding;
        final fits = fullHeight + (lastBlock ? footerHeight : 0) <= available;
        if (fits) {
          blocks.add(NovelPageText(remaining,
              title: block.title, bottomPadding: block.bottomPadding));
          used += fullHeight;
          break;
        }

        final lines = painter.computeLineMetrics();
        var count = lines
            .takeWhile((line) => line.baseline + line.descent <= available)
            .length;
        // Keep some text with the chapter controls rather than making a page
        // containing only buttons when the final paragraph nearly fills a page.
        if (lastBlock && count == lines.length) count--;
        if (count <= 0 && blocks.isNotEmpty) {
          finishPage();
          continue;
        }
        // An unusually small viewport may not fit even one scaled text line.
        // Keep the line intact; the page's vertical scroll fallback exposes it.
        count = max(1, count);
        final line = lines[min(count, lines.length) - 1];
        final position = painter.getPositionForOffset(
            Offset(line.left + 0.1, line.baseline - line.ascent / 2));
        var end = painter.getLineBoundary(position).end;
        if (end <= 0) end = remaining.length;
        end = min(end, remaining.length);
        final text = remaining.substring(0, end);
        final part = TextPainter(
          text:
              TextSpan(text: text, style: block.title ? titleStyle : bodyStyle),
          textDirection: textDirection,
          textAlign: block.title ? TextAlign.center : TextAlign.start,
          textScaler: textScaler,
          locale: locale,
          textHeightBehavior: const TextHeightBehavior(),
        )..layout(maxWidth: width);
        final partHeight = part.height;
        part.dispose();
        remaining = remaining.substring(end);
        final gap = remaining.isEmpty
            ? min(
                block.bottomPadding,
                max(0.0,
                    available - partHeight - (lastBlock ? footerHeight : 0)))
            : 0.0;
        blocks.add(NovelPageText(text, title: block.title, bottomPadding: gap));
        used += partHeight + gap;
        if (remaining.isNotEmpty) finishPage();
      } finally {
        painter.dispose();
      }
    }
  }
  if (blocks.isNotEmpty || pages.isEmpty) finishPage();
  return pages;
}
