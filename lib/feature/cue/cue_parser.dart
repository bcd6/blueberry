import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
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

      // Define encodings to try in order
      final encodings = [utf8, ascii];

      List<String> lines = [];
      Exception? lastError;

      // Try each encoding until successful
      for (final encoding in encodings) {
        try {
          debugPrint('Trying encoding: ${encoding.name}');
          lines = await file.readAsLines(encoding: encoding);
          debugPrint('Successfully read with ${encoding.name}');
          lastError = null;
          break;
        } catch (e) {
          lastError = Exception('Failed with ${encoding.name}: $e');
          continue;
        }
      }

      // If all encodings failed
      if (lines.isEmpty) {
        throw lastError ?? Exception('Failed to read file with all encodings');
      }

      // Continue with parsing
      final parseState = _CueParseState();

      for (final line in lines) {
        _parseLine(line.trim(), parseState);
      }

      _addTrackIfValid(parseState);
      await _calculateTrackDurations(cuePath, parseState);

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
          title:
              state.currentTitle.isNotEmpty ? state.currentTitle : 'No Title',
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
    } else {
      debugPrint('Skipping invalid track');
    }
  }

  static Future<void> _calculateTrackDurations(
    String cuePath,
    _CueParseState state,
  ) async {
    final tracks = state.tracks;
    if (tracks.isEmpty) return;

    // Get audio file path from CUE directory
    Duration audioFileDuration = Duration.zero;
    final cueDir = path.dirname(cuePath);
    final audioFilePath = path.join(cueDir, state.audioFile ?? '');
    try {
      final audioFileMetadata = await MetadataGod.readMetadata(
        file: audioFilePath,
      );
      audioFileDuration = audioFileMetadata.duration ?? Duration.zero;
    } catch (e) {
      // debugPrint('Error getting audio metadata: $e');
      final durationSeconds = await _getAudioDuration(audioFilePath);
      audioFileDuration = Duration(seconds: durationSeconds?.toInt() ?? 0);
    }

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
      tracks[lastIndex] = CueTrack(
        title: tracks[lastIndex].title,
        start: tracks[lastIndex].start,
        duration:
            audioFileDuration != Duration.zero
                ? audioFileDuration - tracks[lastIndex].start
                : audioFileDuration,
        performer: tracks[lastIndex].performer,
        index: tracks[lastIndex].index,
        isrc: tracks[lastIndex].isrc,
        pregap: tracks[lastIndex].pregap,
        metadata: tracks[lastIndex].metadata,
      );
    }
  }

  static Duration? _parseTime(String timeStr) {
    debugPrint('Parsing time: $timeStr');
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      try {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        final frames = int.parse(parts[2]);

        // Calculate total seconds
        final totalSeconds = minutes * 60 + seconds;
        // Convert frames to milliseconds (75 frames per second in CUE standard)
        final milliseconds = (frames * 1000 / 75).round();

        final duration = Duration(
          seconds: totalSeconds,
          milliseconds: milliseconds,
        );

        debugPrint('Converted $timeStr to ${_formatDuration(duration)}');
        return duration;
      } catch (e) {
        debugPrint('Error parsing time: $e');
        return null;
      }
    }
    return null;
  }

  static String _formatDuration(Duration d) {
    return '${(d.inMinutes).toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}.'
        '${((d.inMilliseconds % 1000) / 10).round().toString().padLeft(2, '0')}';
  }

  static Future<double?> _getAudioDuration(String filePath) async {
    try {
      ProcessResult result = await Process.run('ffprobe', [
        '-i',
        filePath,
        '-show_entries',
        'format=duration',
        '-v',
        'quiet',
        '-of',
        'csv=p=0',
      ]);

      return double.tryParse(result.stdout.trim());
    } catch (e) {
      debugPrint('Error getting duration: $e');
      return null;
    }
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
