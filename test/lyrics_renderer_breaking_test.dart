import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font draws every character as a square of fontSize, so a
// character is 10 wide here.
const _lyrics = TextStyle(fontSize: 10);
const _chords = TextStyle(fontSize: 8);

Future<List<String>> _renderRows(
  WidgetTester tester, {
  List<String> breakingCharacters = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          child: LyricsRenderer(
            lyrics: '[C]aa-bb-[G]cc',
            textStyle: _lyrics,
            chordStyle: _chords,
            onTapChord: (_) {},
            breakingCharacters: breakingCharacters,
          ),
        ),
      ),
    ),
  );
  return tester
      .widgetList<ChordLyricRow>(find.byType(ChordLyricRow))
      .map((w) => w.row.lyrics)
      .toList();
}

void main() {
  testWidgets('wraps after breaking characters', (tester) async {
    expect(
      await _renderRows(tester, breakingCharacters: ['-']),
      ['aa-', 'bb-cc'],
    );
  });

  testWidgets('lays out again when breaking characters change', (tester) async {
    expect(await _renderRows(tester), ['aa-bb', '-cc']);
    expect(
      await _renderRows(tester, breakingCharacters: ['-']),
      ['aa-', 'bb-cc'],
    );
  });
}
