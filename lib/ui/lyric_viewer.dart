import 'dart:async';
import 'package:blueberry/domain/track.dart';
import 'package:blueberry/feature/lyric/lyric_loader.dart';
import 'package:blueberry/feature/lyric/lyric_parser.dart';
import 'package:blueberry/feature/lyric/model/lyric_part.dart';
import 'package:flutter/material.dart';

class LyricViewer extends StatefulWidget {
  final Track track;
  final Stream<Duration> currentPositionStream;

  const LyricViewer({
    super.key,
    required this.track,
    required this.currentPositionStream,
  });

  @override
  State<LyricViewer> createState() => _LyricViewerState();
}

class _LyricViewerState extends State<LyricViewer> {
  StreamSubscription? _currentPositionSubscription;
  List<LyricLine>? _lyrics;
  int _currentIndex = 0;
  int _currentPartIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLyricFile();
    _setupDurationStream();
  }

  @override
  void didUpdateWidget(covariant LyricViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track != oldWidget.track) {
      debugPrint('\n=== Track Changed ===');
      debugPrint('Old track: ${oldWidget.track.title}');
      debugPrint('New track: ${widget.track.title}');

      // Reset state
      setState(() {
        _lyrics = null;
        _currentIndex = 0;
        _currentPartIndex = 0;
      });

      // Cancel existing subscription
      _currentPositionSubscription?.cancel();
      _currentPositionSubscription = null;

      // Load new lyrics and setup stream
      _loadLyricFile();
      _setupDurationStream();

      debugPrint('=== Track Change Complete ===\n');
    }
  }

  @override
  void dispose() {
    _currentPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLyricFile() async {
    debugPrint('\n=== Loading Lyrics ===');
    debugPrint('Track: ${widget.track.title}');
    debugPrint('Path: ${widget.track.path}');

    final content = await LyricLoader.loadLyricContent(
      widget.track.path,
      widget.track.title,
    );
    if (content != null) {
      debugPrint('Lyric content loaded: ${content.length} characters');
      final lyrics = LyricParser.parse(content);
      debugPrint('Parsed ${lyrics.length} lyric lines');

      if (lyrics.isNotEmpty) {
        debugPrint('First line: ${lyrics[0].fullText}');
        debugPrint('First timestamp: ${lyrics[0].startTime}');
      }

      setState(() {
        _lyrics = lyrics;
        _currentIndex = 0;
        _currentPartIndex = 0;
      });
    } else {
      debugPrint('No lyrics found');
    }
    debugPrint('=== Lyrics Loading Complete ===\n');
  }

  Future<void> _setupDurationStream() async {
    debugPrint('\n=== Setting up position stream ===');

    await _currentPositionSubscription?.cancel();

    if (_lyrics == null) {
      return;
    }
    _currentPositionSubscription = widget.currentPositionStream.listen(
      (position) {
        _updateCurrentPosition(position);
      },
      onError: (error) {
        debugPrint('Position stream error: $error');
      },
      cancelOnError: false,
    );

    debugPrint('=== Position stream setup complete ===\n');
  }

  void _updateCurrentPosition(Duration position) {
    if (_lyrics == null) {
      debugPrint('No lyrics available for position update');
      return;
    }

    final ms = position.inMilliseconds;
    var foundLine = false;

    // debugPrint('Updating position: ${position.inSeconds}s');

    for (var i = _lyrics!.length - 1; i >= 0; i--) {
      final line = _lyrics![i];
      if (line.startTime.inMilliseconds <= ms) {
        // Find current part within line
        for (var j = line.parts.length - 1; j >= 0; j--) {
          if (line.parts[j].timestamp.inMilliseconds <= ms) {
            if (_currentIndex != i || _currentPartIndex != j) {
              debugPrint('Updating to line $i, part $j: ${line.parts[j].text}');
              setState(() {
                _currentIndex = i;
                _currentPartIndex = j;
              });
            }
            foundLine = true;
            break;
          }
        }
        if (foundLine) break;
      }
    }
  }

  Widget _buildLyricLine(LyricLine line, bool isCurrent) {
    if (!isCurrent) {
      return Text(
        line.fullText,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
      );
    }

    return Wrap(
      children:
          line.parts.map((part) {
            final isActive = line.parts.indexOf(part) <= _currentPartIndex;
            return Text(
              part.text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Text(
          widget.track.title,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final displayLines = <Widget>[];

    // Previous line
    if (_currentIndex > 0) {
      displayLines.add(_buildLyricLine(_lyrics![_currentIndex - 1], false));
    }

    // Current line
    displayLines.add(_buildLyricLine(_lyrics![_currentIndex], true));

    // Next line
    if (_currentIndex < _lyrics!.length - 1) {
      displayLines.add(_buildLyricLine(_lyrics![_currentIndex + 1], false));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.track.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...displayLines.map(
            (widget) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: widget,
            ),
          ),
        ],
      ),
    );
  }
}
