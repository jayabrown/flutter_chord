import 'chord_lyrics_line.dart';

class ChordLyricsDocument {
  final List<ChordLyricsLine> _chordLyricsLines;
  final List<List<ChordLyricsLine>>? _additionalLyrics;
  final int? capo;
  final String? title;
  final String? artist;
  final String? key;

  ChordLyricsDocument(this._chordLyricsLines,
      {List<List<ChordLyricsLine>>? additionalLyrics,
      this.capo,
      this.title,
      this.artist,
      this.key})
      : _additionalLyrics = additionalLyrics;

  /// count of how many additional sets of lyrics there are
  int get _lyricsSetCount => _additionalLyrics?.length ?? 0;

  /// count of whichever list is longest
  int get _longestLength {
    int longest = _chordLyricsLines.length;
    if (_additionalLyrics != null) {
      for (var lyricSet in _additionalLyrics!) {
        if (lyricSet.length > longest) {
          longest = lyricSet.length;
        }
      }
    }
    return longest;
  }

  /// iterate over lyrics and additional lyrics
  List<ChordLyricsLine> get lines {
    // insert additional lyrics
    List<ChordLyricsLine> zippedLines = [];
    for (int i = 0; i < _chordLyricsLines.length; i++) {
      zippedLines.add(_chordLyricsLines[i]);
      for (int j = 0; j < _lyricsSetCount; j++) {
        // prevent going beyond the length of the additional lyrics
        if (i < _additionalLyrics![j].length) {
          zippedLines.add(_additionalLyrics![j][i]);
        }
      }
    }
    // grab any leftover additional lyrics
    for (int i = _chordLyricsLines.length; i < _longestLength; i++) {
      for (int j = 0; j < _lyricsSetCount; j++) {
        if (i < _additionalLyrics![j].length) {
          zippedLines.add(_additionalLyrics![j][i]);
        }
      }
    }
    return zippedLines;
  }
}
