import 'track.dart';

class Playlist {
  final String name;
  final List<Track> tracks;
  final String? cuePath;
  final Map<String, String> metadata;

  Playlist({
    required this.name,
    required this.tracks,
    this.cuePath,
    this.metadata = const {},
  });

  bool get isCueSheet => cuePath != null;
}
