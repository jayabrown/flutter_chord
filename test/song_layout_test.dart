import 'package:flutter/widgets.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font draws every character as a square of fontSize, so a
// character is 10 wide here.
const _lyrics = TextStyle(fontSize: 10);
const _chords = TextStyle(fontSize: 8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final style = LyricsStyle(lyrics: _lyrics, chords: _chords);

  group('wrapText', () {
    test('keeps a line that fits whole', () {
      expect(wrapText('ab cd', _lyrics, 50).map((s) => s.text), ['ab cd']);
    });

    test('breaks at whitespace and drops it at the break', () {
      final segments = wrapText('aaa bbb ccc', _lyrics, 70);
      expect(segments.map((s) => s.text), ['aaa bbb', 'ccc']);
      expect(segments.map((s) => s.start), [0, 8]);
    });

    test('breaks an over-long word between characters', () {
      final segments = wrapText('abcdefgh', _lyrics, 30);
      expect(segments.map((s) => s.text), ['abc', 'def', 'gh']);
      expect(segments.map((s) => s.start), [0, 3, 6]);
    });

    test('ignores trailing whitespace when checking the fit', () {
      expect(wrapText('abcde ', _lyrics, 50).length, 1);
    });

    test('breaks after a breaking character and keeps it on the row', () {
      final segments = wrapText(
        'aa-bb-cc',
        _lyrics,
        50,
        TextScaler.noScaling,
        ['-'],
      );
      expect(segments.map((s) => s.text), ['aa-', 'bb-cc']);
      expect(segments.map((s) => s.start), [0, 3]);
    });

    test('without breaking characters splits the word between characters', () {
      expect(
        wrapText('aa-bb-cc', _lyrics, 50).map((s) => s.text),
        ['aa-bb', '-cc'],
      );
    });

    test('still breaks at whitespace with breaking characters', () {
      final segments = wrapText(
        'aa bb/cc',
        _lyrics,
        50,
        TextScaler.noScaling,
        ['/'],
      );
      expect(segments.map((s) => s.text), ['aa', 'bb/cc']);
      expect(segments.map((s) => s.start), [0, 3]);
    });

    test('keeps a run of breaking characters together', () {
      final segments = wrapText(
        'aa--bb--cc',
        _lyrics,
        60,
        TextScaler.noScaling,
        ['-'],
      );
      expect(segments.map((s) => s.text), ['aa--', 'bb--cc']);
    });

    test('treats regex characters in breaking characters literally', () {
      expect(
        wrapText('aa.bb.cc', _lyrics, 50, TextScaler.noScaling, ['.'])
            .map((s) => s.text),
        ['aa.', 'bb.cc'],
      );
      // An unescaped '.' would match every character and pack 'ab cd'.
      expect(
        wrapText('ab cdefgh', _lyrics, 50, TextScaler.noScaling, ['.'])
            .map((s) => s.text),
        ['ab', 'cdefg', 'h'],
      );
    });
  });

  group('layoutLine', () {
    test('places a chord over its character', () {
      final row = layoutLine(
        parseLine('ab[C]cd'),
        style: style,
        maxWidth: 1000,
      ).single;
      expect(row.chords.single.x, 20);
    });

    test('pushes a colliding chord just past the previous one', () {
      final row = layoutLine(
        parseLine('[Am][G]abcdefgh'),
        style: style,
        maxWidth: 1000,
      ).single;
      expect(row.chords.map((c) => c.x), [0, 16]);
    });

    test('does not drift chords after a collision', () {
      final row = layoutLine(
        parseLine('[Am][G]abcdefgh[D]ij'),
        style: style,
        maxWidth: 1000,
      ).single;
      expect(row.chords.last.x, 80);
    });

    test('moves chords with their syllables onto wrapped rows', () {
      final rows = layoutLine(
        parseLine('[C]aaa [G]bbb [D]ccc'),
        style: style,
        maxWidth: 70,
      );
      expect(rows.map((r) => r.lyrics), ['aaa bbb', 'ccc']);
      expect(rows.first.chords.map((c) => '${c.name}@${c.x}'), [
        'C@0.0',
        'G@40.0',
      ]);
      expect(rows.last.chords.map((c) => '${c.name}@${c.x}'), ['D@0.0']);
    });

    test('moves chords with their syllables at breaking characters', () {
      final rows = layoutLine(
        parseLine('[C]aa-bb-[G]cc'),
        style: style,
        maxWidth: 50,
        breakingCharacters: ['-'],
      );
      expect(rows.map((r) => r.lyrics), ['aa-', 'bb-cc']);
      expect(rows.first.chords.map((c) => '${c.name}@${c.x}'), ['C@0.0']);
      expect(rows.last.chords.map((c) => '${c.name}@${c.x}'), ['G@30.0']);
    });

    test('transposes chord names', () {
      final row = layoutLine(
        parseLine('[C]a[Am]b'),
        style: style,
        maxWidth: 1000,
        transposer: ChordTransposer(ChordNotation.american, transpose: 2),
      ).single;
      expect(row.chords.map((c) => c.name), ['D', 'Bm']);
    });

    test('drops chords and the chord row height when chords are off', () {
      final row = layoutLine(
        parseLine('[C]abc'),
        style: style,
        maxWidth: 1000,
        showChords: false,
      ).single;
      expect(row.chords, isEmpty);
      expect(row.chordRowHeight, 0);
    });
  });

  group('layoutSong', () {
    test('keeps label stanzas with the next one', () {
      final layout = layoutSong(
        parseSong('Verse 2\n\n[G]abc'),
        style: style,
        maxWidth: 1000,
      );
      expect(layout.stanzas.map((s) => s.keepWithNext), [true, false]);
    });

    test('stanza height adds row heights and row spacing', () {
      final layout = layoutSong(
        parseSong('[C]a\nb'),
        style: style,
        maxWidth: 1000,
        rowSpacing: 4,
      );
      final stanza = layout.stanzas.single;
      expect(
        stanza.height,
        stanza.rows[0].height + 4 + stanza.rows[1].height,
      );
    });
  });
  group('additional lyrics', () {
    const additionalStyle = TextStyle(fontSize: 6);
    final withAdditional = LyricsStyle(
      lyrics: _lyrics,
      chords: _chords,
      additional: additionalStyle,
    );

    test('follow all wrapped rows of their line', () {
      final song = parseSong(
        '[C]aaa [G]bbb [D]ccc\n[Am]ddd',
        additionalLyrics: ['one\ntwo', 'uno\ndos'],
      );
      final rows = layoutSong(
        song,
        style: withAdditional,
        maxWidth: 70,
      ).rows.toList();
      expect(rows.map((r) => r.lyrics), [
        'aaa bbb',
        'ccc',
        'one',
        'uno',
        'ddd',
        'two',
        'dos',
      ]);
      expect(rows.map((r) => r.isAdditional), [
        false,
        false,
        true,
        true,
        false,
        true,
        true,
      ]);
    });

    test('use the additional style and have no chords', () {
      final rows = layoutLine(
        parseSong('[C]abc', additionalLyrics: ['xyz']).lines.single,
        style: withAdditional,
        maxWidth: 1000,
      );
      final extra = rows.last;
      expect(extra.lyricStyle, additionalStyle);
      expect(extra.chords, isEmpty);
      expect(extra.chordRowHeight, 0);
      expect(extra.lyricWidth, 18);
      expect(extra.height, 6);
    });

    test('default to the lyrics style', () {
      final rows = layoutLine(
        parseSong('abc', additionalLyrics: ['xyz']).lines.single,
        style: style,
        maxWidth: 1000,
      );
      expect(rows.last.lyricStyle, _lyrics);
    });

    test('wrap to the width, at breaking characters too', () {
      final rows = layoutLine(
        parseSong('ab', additionalLyrics: ['aa-bb-cc']).lines.single,
        style: style,
        maxWidth: 50,
        breakingCharacters: ['-'],
      );
      expect(rows.map((r) => r.lyrics), ['ab', 'aa-', 'bb-cc']);
    });

    test('skip empty additional lines', () {
      final rows = layoutLine(
        parseSong('ab\ncd', additionalLyrics: ['\nxy']).lines.first,
        style: style,
        maxWidth: 1000,
      );
      expect(rows.map((r) => r.lyrics), ['ab']);
    });

    test('past the end of the lyrics lay out without a lyric row', () {
      final layout = layoutSong(
        parseSong('ab', additionalLyrics: ['one\ntwo']),
        style: style,
        maxWidth: 1000,
      );
      expect(layout.stanzas.last.rows.map((r) => r.lyrics), ['two']);
    });

    test('count towards the stanza height', () {
      final layout = layoutSong(
        parseSong('a', additionalLyrics: ['b']),
        style: withAdditional,
        maxWidth: 1000,
        rowSpacing: 4,
      );
      expect(layout.stanzas.single.height, 10 + 4 + 6);
    });
  });
}
