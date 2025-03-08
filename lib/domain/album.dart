import 'playlist.dart';

class Album {
  final String folderPath;
  final String name;
  final String coverPath;
  final List<Playlist> playlists;
  final List<String> regularFiles;
  final List<String> cueFiles;

  Album({
    required this.folderPath,
    required this.name,
    required this.coverPath,
    this.playlists = const [],
    this.regularFiles = const [],
    this.cueFiles = const [],
  });
}
