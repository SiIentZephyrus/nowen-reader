import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowen_reader/features/reader/novel_pagination.dart';

void main() {
  test('long title and paragraphs preserve all text and Unicode across pages',
      () {
    final title = List.filled(12, '很长的章节标题📖').join();
    final paragraph =
        List.generate(30, (i) => '第$i句👨‍👩‍👧‍👦e\u0301正文。').join();
    final pages = paginateNovelText(
      title: title,
      paragraphs: [paragraph],
      size: const Size(260, 240),
      bodyStyle: const TextStyle(fontSize: 20, height: 1.8),
      titleStyle: const TextStyle(fontSize: 24, height: 1.4),
      textScaler: const TextScaler.linear(1.5),
      textDirection: TextDirection.ltr,
      footerHeight: 70,
    );
    expect(pages.length, greaterThan(3));
    final blocks = pages.expand((page) => page.blocks).toList();
    expect(
        blocks.where((block) => block.title).map((block) => block.text).join(),
        title);
    expect(
        blocks.where((block) => !block.title).map((block) => block.text).join(),
        '\u3000\u3000$paragraph');
    for (final block in blocks) {
      expect(block.text.runes, isNot(contains(0xfffd)));
      expect(block.text.runes.any((rune) => rune >= 0xd800 && rune <= 0xdfff),
          isFalse);
      expect(block.text.runes.first, isNot(anyOf(0x200d, 0x0301)));
    }
    for (var i = 0; i < pages.length; i++) {
      expect(pages[i].contentHeight + (i == pages.length - 1 ? 70 : 0),
          lessThanOrEqualTo(240));
    }
  });

  test('chapter controls share the final page with text without overflow', () {
    final paragraphs = List.generate(20, (i) => '第$i段正文');
    final pages = paginateNovelText(
      title: '标题',
      paragraphs: paragraphs,
      size: const Size(240, 140),
      bodyStyle: const TextStyle(fontSize: 18, height: 1.5),
      titleStyle: const TextStyle(fontSize: 22, height: 1.4),
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
      footerHeight: 70,
    );
    expect(pages.last.blocks, isNotEmpty);
    expect(pages.last.contentHeight + 70, lessThanOrEqualTo(140));
    expect(
        pages
            .expand((page) => page.blocks)
            .where((block) => !block.title)
            .map((block) => block.text)
            .join(),
        paragraphs.map((p) => '\u3000\u3000$p').join());
  });
}
