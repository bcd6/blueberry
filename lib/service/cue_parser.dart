import 'dart:io';
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
  final Map<String, String> metadata; // Add metadata field for REM tags

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
  final Map<String, String> metadata; // Add metadata field for REM tags

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
      final lines = await file.readAsLines();

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

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.startsWith('REM ')) {
          final parts = trimmed.substring(4).split(' ');
          if (parts.length >= 2) {
            final key = parts[0];
            final value = parts.sublist(1).join(' ');
            if (!isInTrack) {
              albumMetadata[key] = value;
            } else {
              currentMetadata[key] = value;
            }
          }
        } else if (trimmed.startsWith('FILE ')) {
          final match = RegExp(r'FILE "([^"]+)"').firstMatch(trimmed);
          if (match != null) {
            audioFile = match.group(1);
          }
        } else if (trimmed.startsWith('TITLE ')) {
          final match = RegExp(r'TITLE "([^"]+)"').firstMatch(trimmed);
          if (match != null) {
            if (!isInTrack) {
              albumTitle = match.group(1) ?? '';
            } else {
              currentTitle = match.group(1) ?? '';
            }
          }
        } else if (trimmed.startsWith('PERFORMER ')) {
          final match = RegExp(r'PERFORMER "([^"]+)"').firstMatch(trimmed);
          if (match != null) {
            if (!isInTrack) {
              albumPerformer = match.group(1) ?? '';
            } else {
              currentPerformer = match.group(1) ?? '';
            }
          }
        } else if (trimmed.startsWith('TRACK ')) {
          if (isInTrack && currentStart != null) {
            debugPrint('\nAdding track:');
            debugPrint('  Index: $trackIndex');
            debugPrint('  Title: $currentTitle');
            debugPrint(
              '  Performer: ${currentPerformer.isEmpty ? albumPerformer : currentPerformer}',
            );
            debugPrint('  Start: ${_formatDuration(currentStart)}');
            debugPrint(
              '  Pregap: ${pregapStart != null ? _formatDuration(currentStart - pregapStart) : "none"}',
            );
            debugPrint('  ISRC: ${currentIsrc ?? "none"}');
            debugPrint('  Metadata: $currentMetadata');

            tracks.add(
              CueTrack(
                title: currentTitle,
                start: currentStart,
                performer:
                    currentPerformer.isEmpty
                        ? albumPerformer
                        : currentPerformer,
                index: trackIndex,
                isrc: currentIsrc,
                pregap: pregapStart != null ? currentStart - pregapStart : null,
                metadata: Map.from(currentMetadata),
              ),
            );
          }
          isInTrack = true;
          trackIndex = int.tryParse(trimmed.split(' ')[1]) ?? trackIndex;
          currentTitle = '';
          currentPerformer = '';
          currentIsrc = null;
          pregapStart = null;
          currentStart = null;
          currentMetadata.clear();
        } else if (trimmed.startsWith('ISRC ')) {
          currentIsrc = trimmed.substring(5).trim();
        } else if (trimmed.startsWith('INDEX ')) {
          final parts = trimmed.split(' ');
          if (parts.length == 3) {
            final index = parts[1];
            final time = _parseTime(parts[2]);
            if (time != null) {
              if (index == '00') {
                pregapStart = time;
              } else if (index == '01') {
                currentStart = time;
              }
            }
          }
        }
      }

      // Add last track
      if (isInTrack && currentStart != null) {
        tracks.add(
          CueTrack(
            title: currentTitle,
            start: currentStart,
            performer:
                currentPerformer.isEmpty ? albumPerformer : currentPerformer,
            index: trackIndex,
            isrc: currentIsrc,
            pregap: pregapStart != null ? currentStart - pregapStart : null,
            metadata: Map.from(currentMetadata),
          ),
        );
      }

      // Calculate track durations
      if (tracks.isNotEmpty) {
        debugPrint('\n=== Track list after sorting ===');
        for (var track in tracks) {
          debugPrint('Track ${track.index}: ${track.title}');
        }

        // Sort tracks by index first to ensure correct order
        tracks.sort((a, b) => a.index.compareTo(b.index));

        // Calculate durations using track start times
        for (var i = 0; i < tracks.length - 1; i++) {
          final duration = tracks[i + 1].start - tracks[i].start;
          debugPrint('\nCalculating duration for track ${tracks[i].index}:');
          debugPrint('  Start: ${_formatDuration(tracks[i].start)}');
          debugPrint(
            '  Next track starts at: ${_formatDuration(tracks[i + 1].start)}',
          );
          debugPrint('  Duration: ${_formatDuration(duration)}');

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

        // For last track, estimate duration as same as previous track
        if (tracks.length > 1) {
          final lastIndex = tracks.length - 1;
          final previousDuration =
              tracks[lastIndex - 1].duration ?? Duration.zero;
          debugPrint('\nLast track (${tracks[lastIndex].index}):');
          debugPrint('  Start: ${_formatDuration(tracks[lastIndex].start)}');
          debugPrint(
            '  Estimated duration: ${_formatDuration(previousDuration)}',
          );
          tracks[lastIndex] = CueTrack(
            title: tracks[lastIndex].title,
            start: tracks[lastIndex].start,
            duration: previousDuration, // Use previous track's duration
            performer: tracks[lastIndex].performer,
            index: tracks[lastIndex].index,
            isrc: tracks[lastIndex].isrc,
            pregap: tracks[lastIndex].pregap,
            metadata: tracks[lastIndex].metadata,
          );
        }
      }

      debugPrint('\n=== CUE parsing completed ===\n');
      return audioFile != null
          ? CueSheet(
            audioFile: audioFile,
            tracks: tracks,
            title: albumTitle,
            performer: albumPerformer,
            metadata: albumMetadata,
          )
          : null;
    } catch (e) {
      debugPrint('Error parsing CUE file: $e');
      return null;
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

  // Add helper method for formatting durations
  static String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}.${(d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }
}
