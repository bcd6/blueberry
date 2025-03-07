import 'package:blueberry/domain/track.dart';
import 'package:blueberry/service/cue_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'playlist.dart';

class Album {
  final String folderPath;
  final String name;
  final String coverPath;
  final List<Playlist> playlists;
  final List<String> cueFiles; // Store CUE file paths instead of parsed data

  Album({
    required this.folderPath,
    required this.name,
    required this.coverPath,
    required this.playlists,
    this.cueFiles = const [],
  });

  Future<List<Playlist>> loadCuePlaylists() async {
    final List<Playlist> cuePlaylists = [];

    for (final cuePath in cueFiles) {
      try {
        final cueSheet = await CueParser.parse(cuePath);
        if (cueSheet != null) {
          final audioDir = path.dirname(cuePath);
          final audioPath = path.join(audioDir, cueSheet.audioFile);

          final cueTracks =
              cueSheet.tracks
                  .where((t) => t.title.isNotEmpty)
                  .map(
                    (t) => Track(
                      path: audioPath,
                      title: t.title,
                      performer: t.performer,
                      duration: t.duration,
                      startOffset: t.start,
                      metadata: t.metadata,
                      isCueTrack: true,
                    ),
                  )
                  .toList();

          if (cueTracks.isNotEmpty) {
            cuePlaylists.add(
              Playlist(
                name:
                    cueSheet.title.isNotEmpty
                        ? cueSheet.title
                        : path.basenameWithoutExtension(cuePath),
                tracks: cueTracks,
                cuePath: cuePath,
                metadata: cueSheet.metadata,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error loading CUE file $cuePath: $e');
      }
    }
    return cuePlaylists;
  }
}
