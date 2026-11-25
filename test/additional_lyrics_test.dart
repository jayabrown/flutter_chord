import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const textStyle = TextStyle(fontSize: 18);

  /// Runs [processText] on a narrow screen so that long lines are split.
  Future<ChordLyricsDocument> process(
    WidgetTester tester, {
    required String text,
    required List<String> additionalLyrics,
  }) async {
    tester.view.physicalSize = const Size(300, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late ChordLyricsDocument document;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          document = ChordProcessor(context).processText(
            text: text,
            additionalLyrics: additionalLyrics,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
            breakingCharacters: [' '],
          );
          return Container();
        },
      ),
    );
    return document;
  }

  /// Groups the rendered lines: each additional line, paired with the lyrics
  /// of the rows that came directly before it, as 'rows => additional'.
  List<String> pairs(ChordLyricsDocument document) {
    final result = <String>[];
    final rows = <String>[];
    for (final line in document.lines) {
      if (line is ChordLyricsLine) {
        rows.add(line.lyrics);
      } else {
        result.add('${rows.join(' ')} => $line');
        rows.clear();
      }
    }
    return result;
  }

  testWidgets('additional lyrics stay under their line when a line wraps',
      (tester) async {
    final document = await process(
      tester,
      text: [
        '[C]Short one',
        '[G]This line is far too long to fit on [Am]such a narrow screen',
        '[F]Short two',
        '[C]Another line that is much too long for the [G]available width',
        '[C]Short three',
      ].join('\n'),
      additionalLyrics: ['A\nB\nC\nD\nE'],
    );

    // Make sure the test actually exercises wrapping.
    expect(document.chordLyricsLines.length, greaterThan(5));

    expect(pairs(document), [
      'Short one => A',
      'This line is far too long to fit on such a narrow screen => B',
      'Short two => C',
      'Another line that is much too long for the available width => D',
      'Short three => E',
    ]);
  });

  testWidgets('metadata lines do not shift additional lyrics', (tester) async {
    final document = await process(
      tester,
      text: '{title: Example}\n[C]First\n[G]Second',
      additionalLyrics: ['\nA\nB'],
    );

    expect(pairs(document), ['First => A', 'Second => B']);
  });

  testWidgets('extra additional lines are kept at the end', (tester) async {
    final document = await process(
      tester,
      text: '[C]First\n[G]Second',
      additionalLyrics: ['A\nB\nC'],
    );

    expect(document.lines.last, 'C');
    expect(pairs(document).take(2), ['First => A', 'Second => B']);
  });
}
