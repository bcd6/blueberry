import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class CueTrack {
  final String title;
  final Duration start;
  final Duration? duration;
  final String performer;
  final int index;
  final String? isrc;
  final Duration? pregap;
  final Map<String, String> metadata;

  CueTrack({
    required this.title,
    required this.start,
    this.duration,
    required this.performer,
    required this.index,
    this.isrc,
    this.pregap,
    this.metadata = const {},
  });
}

class CueSheet {
  final String audioFile;
  final List<CueTrack> tracks;
  final String title;
  final String performer;
  final Map<String, String> metadata;

  CueSheet({
    required this.audioFile,
    required this.tracks,
    this.title = '',
    this.performer = '',
    this.metadata = const {},
  });
}

class CueParser {
  static Future<CueSheet?> parse(String cuePath) async {
    try {
      debugPrint('\n=== Starting CUE parsing: ${path.basename(cuePath)} ===');
      final file = File(cuePath);
      final lines = await file.readAsLines(encoding: utf8);

      final parseState = _CueParseState();

      for (final line in lines) {
        _parseLine(line.trim(), parseState);
      }

      _addTrackIfValid(parseState);
      _calculateTrackDurations(parseState.tracks);

      debugPrint('\n=== CUE parsing completed ===\n');
      return parseState.audioFile != null
          ? CueSheet(
            audioFile: parseState.audioFile!,
            tracks: parseState.tracks,
            title: parseState.albumTitle,
            performer: parseState.albumPerformer,
            metadata: parseState.albumMetadata,
          )
          : null;
    } catch (e, stackTrace) {
      debugPrint('Error parsing CUE file: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static void _parseLine(String line, _CueParseState state) {
    if (line.startsWith('REM ')) {
      _parseRem(line, state);
    } else if (line.startsWith('FILE ')) {
      _parseFile(line, state);
    } else if (line.startsWith('TITLE ')) {
      _parseTitle(line, state);
    } else if (line.startsWith('PERFORMER ')) {
      _parsePerformer(line, state);
    } else if (line.startsWith('TRACK ')) {
      _parseTrack(line, state);
    } else if (line.startsWith('ISRC ')) {
      state.currentIsrc = line.substring(5).trim();
    } else if (line.startsWith('INDEX ')) {
      _parseIndex(line, state);
    }
  }

  static void _parseRem(String line, _CueParseState state) {
    final parts = line.substring(4).split(' ');
    if (parts.length >= 2) {
      final key = parts[0];
      final value = parts.sublist(1).join(' ');
      if (!state.isInTrack) {
        state.albumMetadata[key] = value;
      } else {
        state.currentMetadata[key] = value;
      }
    }
  }

  static void _parseFile(String line, _CueParseState state) {
    final match = RegExp(r'FILE "([^"]+)"').firstMatch(line);
    if (match != null) {
      state.audioFile = match.group(1);
    }
  }

  static void _parseTitle(String line, _CueParseState state) {
    final match = RegExp(r'TITLE "([^"]+)"').firstMatch(line);
    if (match != null) {
      if (!state.isInTrack) {
        state.albumTitle = match.group(1) ?? '';
      } else {
        state.currentTitle = match.group(1) ?? '';
      }
    }
  }

  static void _parsePerformer(String line, _CueParseState state) {
    final match = RegExp(r'PERFORMER "([^"]+)"').firstMatch(line);
    if (match != null) {
      final performer = match.group(1) ?? '';
      if (!state.isInTrack) {
        state.albumPerformer = performer;
      } else {
        state.currentPerformer = performer;
      }
    }
  }

  static void _parseTrack(String line, _CueParseState state) {
    _addTrackIfValid(state);
    state.isInTrack = true;
    state.trackIndex = int.tryParse(line.split(' ')[1]) ?? state.trackIndex;
    state.resetTrackState();
  }

  static void _parseIndex(String line, _CueParseState state) {
    final parts = line.split(' ');
    if (parts.length == 3) {
      final index = parts[1];
      final time = _parseTime(parts[2]);
      if (time != null) {
        if (index == '00') {
          state.pregapStart = time;
        } else if (index == '01') {
          state.currentStart = time;
          debugPrint(
            'Track ${state.trackIndex} starts at ${_formatDuration(time)}',
          );
        }
      }
    }
  }

  static void _addTrackIfValid(_CueParseState state) {
    if (state.isInTrack && state.currentStart != null) {
      state.tracks.add(
        CueTrack(
          title: state.currentTitle,
          start: state.currentStart!,
          performer:
              state.currentPerformer.isEmpty
                  ? state.albumPerformer
                  : state.currentPerformer,
          index: state.trackIndex,
          isrc: state.currentIsrc,
          pregap:
              state.pregapStart != null
                  ? state.currentStart! - state.pregapStart!
                  : null,
          metadata: Map.from(state.currentMetadata),
        ),
      );
    }
  }

  static void _calculateTrackDurations(List<CueTrack> tracks) {
    if (tracks.isEmpty) return;

    tracks.sort((a, b) => a.index.compareTo(b.index));

    for (var i = 0; i < tracks.length - 1; i++) {
      final duration = tracks[i + 1].start - tracks[i].start;
      tracks[i] = CueTrack(
        title: tracks[i].title,
        start: tracks[i].start,
        duration: duration,
        performer: tracks[i].performer,
        index: tracks[i].index,
        isrc: tracks[i].isrc,
        pregap: tracks[i].pregap,
        metadata: tracks[i].metadata,
      );
    }

    // Handle last track duration
    if (tracks.length > 1) {
      final lastIndex = tracks.length - 1;
      final previousDuration = tracks[lastIndex - 1].duration ?? Duration.zero;
      tracks[lastIndex] = CueTrack(
        title: tracks[lastIndex].title,
        start: tracks[lastIndex].start,
        duration: previousDuration,
        performer: tracks[lastIndex].performer,
        index: tracks[lastIndex].index,
        isrc: tracks[lastIndex].isrc,
        pregap: tracks[lastIndex].pregap,
        metadata: tracks[lastIndex].metadata,
      );
    }
  }

  static Duration? _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      try {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        final frames = int.parse(parts[2]);
        return Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: (frames * 1000 ~/ 75),
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'
        '.${(d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }
}

class _CueParseState {
  String? audioFile;
  String albumTitle = '';
  String albumPerformer = '';
  final albumMetadata = <String, String>{};
  final tracks = <CueTrack>[];

  String currentTitle = '';
  String currentPerformer = '';
  String? currentIsrc;
  Duration? currentStart;
  Duration? pregapStart;
  int trackIndex = 1;
  final currentMetadata = <String, String>{};

  bool isInTrack = false;

  void resetTrackState() {
    currentTitle = '';
    currentPerformer = '';
    currentIsrc = null;
    pregapStart = null;
    currentStart = null;
    currentMetadata.clear();
  }
}
