enum LineType {
  chorus,
  main, // main lyrics
  extra, // additional lyrics (translations, etc)
  header,
  metadata, // skip these lines
  comment,
}

class ChordLyricsLine {
  List<Chord> chords;
  String lyrics;
  LineType lineType;

  ChordLyricsLine({lineType = LineType.main})
      : chords = [],
        lyrics = '',
        lineType = lineType;

  ChordLyricsLine.line(this.chords, this.lyrics, this.lineType);

  @override
  String toString() {
    return 'ChordLyricsLine($chords, lyrics: $lyrics)';
  }
}

class Chord {
  double leadingSpace;
  String chordText;

  Chord(this.leadingSpace, this.chordText);

  @override
  String toString() {
    return 'Chord(leadingSpace: $leadingSpace, chordText: $chordText)';
  }
}
