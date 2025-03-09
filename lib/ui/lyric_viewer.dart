import 'dart:async';
import 'package:blueberry/domain/track.dart';
import 'package:blueberry/feature/lyric/lyric_loader.dart';
import 'package:flutter/material.dart';
import 'package:lrc/lrc.dart';

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
  Lrc? _lyric;

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
      _loadLyricFile();
      _setupDurationStream();
    }
  }

  @override
  void dispose() {
    _currentPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLyricFile() async {
    final lyric = await LyricLoader.loadLyricByAudioFile(
      widget.track.path,
      widget.track.title,
    );
    setState(() {
      _lyric = lyric;
    });
  }

  Future<void> _setupDurationStream() async {
    await _currentPositionSubscription?.cancel();
    _currentPositionSubscription = widget.currentPositionStream.listen(
      (duration) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lyric == null) {
      return Center(
        child: Text(
          widget.track.title,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Text(widget.track.title);
  }
}
