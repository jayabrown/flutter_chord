import 'package:flutter/material.dart';
import 'chord_transposer.dart';
import 'model/chord_lyrics_line.dart';
import 'chord_parser.dart';

class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;

  /// To help stop overflow, this should be the sum of left & right padding
  final int widgetPadding;

  /// Transpose Increment for the Chords,
  /// default value is 0, which means no transpose is applied
  final int transposeIncrement;

  /// Auto Scroll Speed,
  /// default value is 0, which means no auto scroll is applied
  final int scrollSpeed;

  /// Extra height between each line
  final double lineHeight;

  /// Widget before the lyrics starts
  final Widget? leadingWidget;

  /// Widget after the lyrics finishes
  final Widget? trailingWidget;

  /// Horizontal alignment
  final CrossAxisAlignment horizontalAlignment;

  /// Scale factor of chords and lyrics
  final double scaleFactor;

  /// Notation that will be handled by the transposer
  final ChordNotation chordNotation;

  /// Define physics of scrolling
  final ScrollPhysics scrollPhysics;

  /// If not defined it will be the bold version of [textStyle]
  final TextStyle? chorusStyle;

  /// If not defined it will be the italic version of [textStyle]
  final TextStyle? capoStyle;

  /// If not defined it will be the italic version of [textStyle]
  final TextStyle? commentStyle;

  /// Optional external scroll controller, otherwise will be created internally
  final ScrollController? scrollController;

  /// List of characters that will break the line
  final List<String> breakingCharacters;

  const LyricsRenderer(
      {Key? key,
      required this.lyrics,
      required this.textStyle,
      required this.chordStyle,
      required this.onTapChord,
      this.chorusStyle,
      this.commentStyle,
      this.capoStyle,
      this.scaleFactor = 1.0,
      this.showChord = true,
      this.widgetPadding = 0,
      this.transposeIncrement = 0,
      this.scrollSpeed = 0,
      this.lineHeight = 8.0,
      this.horizontalAlignment = CrossAxisAlignment.center,
      this.scrollPhysics = const ClampingScrollPhysics(),
      this.leadingWidget,
      this.trailingWidget,
      this.chordNotation = ChordNotation.american,
      this.scrollController,
      this.breakingCharacters = const [' ', ',', '.', '。', '、']})
      : super(key: key);

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  late final ScrollController _controller;
  late TextStyle chorusStyle;
  late TextStyle capoStyle;
  late TextStyle commentStyle;
  bool _isChorus = false;
  bool _isComment = false;

  @override
  void initState() {
    super.initState();
    chorusStyle = widget.chorusStyle ??
        widget.textStyle.copyWith(fontWeight: FontWeight.bold);
    capoStyle = widget.capoStyle ??
        widget.textStyle.copyWith(fontStyle: FontStyle.italic);
    commentStyle = widget.commentStyle ??
        widget.textStyle.copyWith(
          fontStyle: FontStyle.italic,
          fontSize: widget.textStyle.fontSize! - 2,
        );
    _controller = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // executes after build
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle getLineTextStyle() {
    if (_isChorus) {
      return chorusStyle;
    } else if (_isComment) {
      return commentStyle;
    } else {
      return widget.textStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    ChordProcessor _chordProcessor =
        ChordProcessor(context, widget.chordNotation);
    final chordLyricsDocument = _chordProcessor.processText(
      text: widget.lyrics,
      lyricsStyle: widget.textStyle,
      chordStyle: widget.chordStyle,
      chorusStyle: chorusStyle,
      widgetPadding: widget.widgetPadding,
      scaleFactor: widget.scaleFactor,
      transposeIncrement: widget.transposeIncrement,
      breakingCharacters: widget.breakingCharacters,
    );
    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return SingleChildScrollView(
      controller: _controller,
      physics: widget.scrollPhysics,
      child: Column(
        crossAxisAlignment: widget.horizontalAlignment,
        children: [
          if (widget.leadingWidget != null) widget.leadingWidget!,
          if (chordLyricsDocument.capo != null)
            Text('Capo: ${chordLyricsDocument.capo!}', style: capoStyle),
          ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => SizedBox(
              height: widget.lineHeight,
            ),
            itemBuilder: (context, index) {
              final ChordLyricsLine line =
                  chordLyricsDocument.chordLyricsLines[index];
              if (line.isStartOfChorus()) {
                _isChorus = true;
              }
              if (line.isEndOfChorus()) {
                _isChorus = false;
              }
              if (line.isComment()) {
                _isComment = true;
              } else {
                _isComment = false;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showChord)
                    Row(
                      children: line.chords
                          .map((chord) => Row(
                                children: [
                                  SizedBox(
                                    width: chord.leadingSpace,
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        widget.onTapChord(chord.chordText),
                                    child: RichText(
                                      text: TextSpan(
                                        text: chord.chordText,
                                        style: widget.chordStyle,
                                      ),
                                      textScaler:
                                          TextScaler.linear(widget.scaleFactor),
                                    ),
                                  )
                                ],
                              ))
                          .toList(),
                    ),
                  RichText(
                    text:
                        TextSpan(text: line.lyrics, style: getLineTextStyle()),
                    textScaler: TextScaler.linear(widget.scaleFactor),
                  )
                ],
              );
            },
            itemCount: chordLyricsDocument.chordLyricsLines.length,
          ),
          if (widget.trailingWidget != null) widget.trailingWidget!,
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LyricsRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSpeed != widget.scrollSpeed) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    if (widget.scrollSpeed <= 0) {
      // stop scrolling if the speed is 0 or less
      _controller.jumpTo(_controller.offset);
      return;
    }

    if (_controller.offset >= _controller.position.maxScrollExtent) return;

    final seconds =
        (_controller.position.maxScrollExtent / (widget.scrollSpeed)).floor();

    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(
        seconds: seconds,
      ),
      curve: Curves.linear,
    );
  }
}

class TextRender extends CustomPainter {
  final String text;
  final TextStyle style;
  TextRender(this.text, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
