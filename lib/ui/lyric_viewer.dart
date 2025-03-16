import 'dart:async';
import 'package:blueberry/lyric/lyric_part.dart';
import 'package:blueberry/lyric/lyric_state.dart';
import 'package:blueberry/player/player_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LyricViewer extends StatefulWidget {
  const LyricViewer({super.key});

  @override
  State<LyricViewer> createState() => _LyricViewerState();
}

class _LyricViewerState extends State<LyricViewer> {
  StreamSubscription? _currentPositionSubscription;
  List<LyricLine>? _lyrics;
  int _currentIndex = 0;
  int _currentPartIndex = 0;

  late PlayerState _playerState;
  late LyricState _lyricState;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // @override
  // void didUpdateWidget(covariant LyricViewer oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.track != oldWidget.track) {
  //     debugPrint('\n=== Track Changed ===');
  //     debugPrint('Old track: ${oldWidget.track.title}');
  //     debugPrint('New track: ${widget.track.title}');

  //     // Reset state
  //     setState(() {
  //       _lyrics = null;
  //       _currentIndex = 0;
  //       _currentPartIndex = 0;
  //     });

  //     // Cancel existing subscription
  //     _currentPositionSubscription?.cancel();
  //     _currentPositionSubscription = null;

  //     // Load new lyrics and setup stream
  //     _loadLyricFile();
  //     _setupDurationStream();

  //     debugPrint('=== Track Change Complete ===\n');
  //   }
  // }

  @override
  void dispose() {
    _currentPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return; // Add this check

    _playerState = context.read<PlayerState>();
    _lyricState = context.read<LyricState>();

    if (_playerState.currentTrack != null) {
      await _lyricState.load(_playerState.currentTrack!);
      _setupDurationStream();
    }
  }

  Future<void> _setupDurationStream() async {
    debugPrint('\n=== Setting up position stream ===');

    await _currentPositionSubscription?.cancel();

    _currentPositionSubscription = _playerState.currentPositionStream?.listen(
      (position) {
        if (_lyrics == null) {
          // debugPrint('Position update ignored - no lyrics loaded');
          return;
        }
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
              // debugPrint('Updating to line $i, part $j: ${line.parts[j].text}');
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
    return Wrap(
      spacing: 4,
      children:
          line.parts.map((part) {
            final partIndex = line.parts.indexOf(part);

            // Get next part from same line
            final nextPart =
                partIndex + 1 < line.parts.length
                    ? line.parts[partIndex + 1]
                    : null;

            // Get next line's first part timestamp if this is last part
            final nextLineStartTime =
                _currentIndex + 1 < _lyrics!.length
                    ? _lyrics![_currentIndex + 1].startTime.inMilliseconds
                    : null;

            // Calculate time gap for spacing
            final timeGap =
                nextPart != null
                    ? nextPart.timestamp.inMilliseconds -
                        part.timestamp.inMilliseconds
                    : 0;
            final extraSpacing = timeGap > 500 ? ' ' : '';

            if (!isCurrent) {
              return Text(
                part.text + extraSpacing,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: isCurrent ? 20 : 16,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1.0,
                ),
              );
            }

            // For active parts, create animated highlight effect
            return StreamBuilder<Duration>(
              stream: _playerState.currentPositionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data?.inMilliseconds ?? 0;
                final partStartTime = part.timestamp.inMilliseconds;

                // Use next part timestamp, or next line timestamp, or fallback to 1 second
                final partEndTime =
                    nextPart?.timestamp.inMilliseconds ??
                    nextLineStartTime ??
                    (partStartTime + 1000);

                // Calculate progress within this part's duration
                final partDuration = partEndTime - partStartTime;
                final elapsed = currentPosition - partStartTime;
                final progress =
                    partDuration > 0
                        ? (elapsed / partDuration).clamp(0.0, 1.0)
                        : 1.0;

                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.white38,
                        Colors.white38,
                      ],
                      stops: [0.0, progress, progress, 1.0],
                    ).createShader(bounds);
                  },
                  child: Text(
                    part.text + extraSpacing,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lyrics == null || _lyrics!.isEmpty) {
      return Container();
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayLines.map(
            (widget) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              child: widget,
            ),
          ),
        ],
      ),
    );
  }
}
