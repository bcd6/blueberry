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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _currentPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return;

    final playerState = context.read<PlayerState>();
    final lyricState = context.read<LyricState>();

    if (playerState.currentTrack != null) {
      await lyricState.load(playerState.currentTrack!);
      _setupDurationStream(playerState);
    }
  }

  Future<void> _setupDurationStream(PlayerState playerState) async {
    await _currentPositionSubscription?.cancel();

    _currentPositionSubscription = playerState.currentPositionStream?.listen(
      (position) {
        if (!mounted) return;
        final lyricState = context.read<LyricState>();
        _updateCurrentPosition(position, lyricState);
      },
      onError: (error) {
        debugPrint('Position stream error: $error');
      },
      cancelOnError: false,
    );
  }

  void _updateCurrentPosition(Duration position, LyricState lyricState) {
    if (lyricState.currentLyric.isEmpty) return;

    final ms = position.inMilliseconds;
    var foundLine = false;

    for (var i = lyricState.currentLyric.length - 1; i >= 0; i--) {
      final line = lyricState.currentLyric[i];
      if (line.startTime.inMilliseconds <= ms) {
        for (var j = line.parts.length - 1; j >= 0; j--) {
          if (line.parts[j].timestamp.inMilliseconds <= ms) {
            lyricState.updateIndex(i, j);
            foundLine = true;
            break;
          }
        }
        if (foundLine) break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerState, LyricState>(
      builder: (context, playerState, lyricState, child) {
        if (lyricState.currentLyric.isEmpty) {
          return Container();
        }

        final displayLines = <Widget>[];

        // Previous line
        if (lyricState.currentIndex > 0) {
          displayLines.add(
            _buildLyricLine(
              lyricState.currentLyric[lyricState.currentIndex - 1],
              false,
              playerState,
              lyricState,
            ),
          );
        }

        // Current line
        displayLines.add(
          _buildLyricLine(
            lyricState.currentLyric[lyricState.currentIndex],
            true,
            playerState,
            lyricState,
          ),
        );

        // Next line
        if (lyricState.currentIndex < lyricState.currentLyric.length - 1) {
          displayLines.add(
            _buildLyricLine(
              lyricState.currentLyric[lyricState.currentIndex + 1],
              false,
              playerState,
              lyricState,
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                displayLines
                    .map(
                      (widget) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.centerLeft,
                        child: widget,
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildLyricLine(
    LyricLine line,
    bool isCurrent,
    PlayerState playerState,
    LyricState lyricState,
  ) {
    return Wrap(
      spacing: 4,
      children:
          line.parts.map((part) {
            final partIndex = line.parts.indexOf(part);
            final nextPart =
                partIndex + 1 < line.parts.length
                    ? line.parts[partIndex + 1]
                    : null;
            final nextLineStartTime =
                lyricState.currentIndex + 1 < lyricState.currentLyric.length
                    ? lyricState
                        .currentLyric[lyricState.currentIndex + 1]
                        .startTime
                        .inMilliseconds
                    : null;

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

            return StreamBuilder<Duration>(
              stream: playerState.currentPositionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data?.inMilliseconds ?? 0;
                final partStartTime = part.timestamp.inMilliseconds;
                final partEndTime =
                    nextPart?.timestamp.inMilliseconds ??
                    nextLineStartTime ??
                    (partStartTime + 1000);

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
}
