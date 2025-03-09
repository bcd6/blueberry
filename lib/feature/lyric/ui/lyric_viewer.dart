import 'package:blueberry/domain/track.dart';
import 'package:blueberry/feature/lyric/helper.dart';
import 'package:blueberry/feature/lyric/models/lyric.dart';
import 'package:blueberry/feature/lyric/models/lyric_line.dart';
import 'package:blueberry/feature/lyric/parser/lrc_lyric_parser.dart';
import 'package:blueberry/feature/lyric/ui/widgets/fluid_background.dart';
import 'package:blueberry/feature/lyric/ui/widgets/lines_builder.dart';
import 'package:blueberry/feature/lyric/ui/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// A widget that renders the AMLV based on the [Lyric] instance.
class LyricViewer extends StatefulWidget {
  /// The [Lyric] instance.
  final Track track;

  final Stream<Duration> currentPositionStream;

  /// The color of the active elements.
  final Color? activeColor;

  /// The color of the inactive elements.
  final Color? inactiveColor;

  /// The callback for the backward button.
  /// if `null`, the button will not be displayed.
  final PlaybackControlBuilder? backwardBuilder;

  /// The callback for the forward button.
  /// if `null`, the button will not be displayed.
  final PlaybackControlBuilder? forwardBuilder;

  /// The callback for when the audio is completed.
  final Function? onCompleted;

  /// The callback for when the [LyricLine] is changed.
  final LyricChangedCallback? onLyricChanged;

  /// The size of the player icon.
  final double playerIconSize;

  /// The color of the player icon.
  final Color playerIconColor;

  /// The first color of the gradient background.
  /// this is used for the [FluidBackground] widget alongside `gradientColor2`.
  final Color gradientColor1;

  /// The second color of the gradient background.
  /// this is used for the [FluidBackground] widget alongside `gradientColor1`.
  final Color gradientColor2;

  const LyricViewer({
    super.key,
    required this.track,
    required this.currentPositionStream,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white54,
    this.backwardBuilder,
    this.forwardBuilder,
    this.onCompleted,
    this.onLyricChanged,
    this.playerIconSize = 50,
    this.playerIconColor = Colors.white,
    this.gradientColor1 = Colors.red,
    this.gradientColor2 = Colors.black,
  });

  @override
  State<LyricViewer> createState() => LyricViewerState();
}

class LyricViewerState extends State<LyricViewer> {
  int _currentLyricLine = 0;
  bool isPlaying = false;
  int timeProgress = 0;
  int audioDuration = 0;
  Lyric? _lyric;

  final AutoScrollController _controller = AutoScrollController();
  final LrcLyricParser _lrcLyricParser = LrcLyricParser();

  _jumpToLine(int index, String caller, {bool play = true, Duration? d}) {
    List<LyricLine> lines = _lyric!.lines;
    if (index > lines.length - 1) {
      return;
    }
    if (index == -1) {
      index = lines.length - 1;
    }

    LyricLine line = lines[index];
    _controller.scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
    setState(() {
      _currentLyricLine = index;
      if (play) {}
      if (widget.onLyricChanged != null) {
        widget.onLyricChanged!(line, caller);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLyricFile();

    widget.currentPositionStream.listen((duration) {
      audioDuration = duration.inSeconds;
    });
    widget.currentPositionStream.listen((time) {
      setState(() {
        timeProgress = time.inSeconds;
      });
      if (isPlaying) {
        int i = _lyric!.lines.indexWhere((li) => li.time > time);
        if (i > 0) {
          i--;
        }
        if (i != _currentLyricLine && i < _lyric!.lines.length) {
          _jumpToLine(i, "listener", play: false, d: time);
        }
      }
    });

    super.initState();
  }

  void reloadLyrics() {
    _loadLyricFile();
    _currentLyricLine = 0;
  }

  Future<void> _loadLyricFile() async {
    setState(() => _lyric = null); // Clear current lyrics

    try {
      final trackPath = widget.track.path;
      final directory = path.dirname(trackPath);
      final filename = path.basenameWithoutExtension(trackPath);

      debugPrint('Looking for lyrics: $filename');

      // Try common lyric file extensions
      for (final ext in ['.lrc', '.txt']) {
        final lyricPath = path.join(directory, '$filename$ext');
        final lyricFile = File(lyricPath);

        if (await lyricFile.exists()) {
          debugPrint('Found lyric file: $lyricPath');
          final result = await _lrcLyricParser.parse(lyricFile);
          setState(() async {
            _lyric = result;
          });
          return;
        }
      }

      debugPrint('No lyric file found for: ${widget.track.title}');
    } catch (e) {
      debugPrint('Error loading lyric file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lyric == null) {
      return const Center(
        child: Text(
          'No lyrics available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Scaffold(
      body: FluidBackground(
        color1: widget.gradientColor1,
        color2: widget.gradientColor2,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LyricViewerTitle(
                  lyric: _lyric!,
                  titleColor: widget.activeColor,
                  subtitleColor: widget.inactiveColor,
                ),
                verticalSpace(10),
                LyricLinesBuilder(
                  controller: _controller,
                  currentLyricLine: _currentLyricLine,
                  lines: _lyric!.lines,
                  onLineChanged: (int i, String caller) {
                    return _jumpToLine(i, caller);
                  },
                  activeColor: widget.activeColor,
                  inactiveColor: widget.inactiveColor,
                ),
                verticalSpace(10),
                // LyricViewerControls(
                //   player: player,
                //   timeProgress: timeProgress,
                //   audioDuration: audioDuration,
                //   isPlaying: isPlaying,
                //   iconSize: widget.playerIconSize,
                //   iconColor: widget.playerIconColor,
                //   activeColor: widget.activeColor,
                //   inactiveColor: widget.inactiveColor,
                //   backwardBuilder: widget.backwardBuilder,
                //   forwardBuilder: widget.forwardBuilder,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
