import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font draws every character as a square of fontSize, so a
// character is 10 wide here.
const _lyrics = TextStyle(fontSize: 10);
const _chords = TextStyle(fontSize: 8);
const _additional = TextStyle(fontSize: 6);

Future<List<LaidOutRow>> _renderRows(
  WidgetTester tester, {
  required List<String> additionalLyrics,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 70,
          child: LyricsRenderer(
            lyrics: '[C]aaa [G]bbb [D]ccc\n[Am]ddd',
            additionalLyrics: additionalLyrics,
            textStyle: _lyrics,
            additionalTextStyle: _additional,
            chordStyle: _chords,
            onTapChord: (_) {},
          ),
        ),
      ),
    ),
  );
  return tester
      .widgetList<ChordLyricRow>(find.byType(ChordLyricRow))
      .map((w) => w.row)
      .toList();
}

void main() {
  testWidgets('shows additional lines after each wrapped line', (tester) async {
    final rows = await _renderRows(
      tester,
      additionalLyrics: ['one\ntwo'],
    );
    expect(rows.map((r) => r.lyrics), ['aaa bbb', 'ccc', 'one', 'ddd', 'two']);
    expect(
      rows.where((r) => r.isAdditional).map((r) => r.lyricStyle),
      [_additional, _additional],
    );
  });

  testWidgets('updates when the additional lyrics change', (tester) async {
    await _renderRows(tester, additionalLyrics: ['one\ntwo']);
    final rows = await _renderRows(tester, additionalLyrics: ['uno\ndos']);
    expect(rows.map((r) => r.lyrics), ['aaa bbb', 'ccc', 'uno', 'ddd', 'dos']);

    final none = await _renderRows(tester, additionalLyrics: []);
    expect(none.map((r) => r.lyrics), ['aaa bbb', 'ccc', 'ddd']);
  });
}
