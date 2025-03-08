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
}
