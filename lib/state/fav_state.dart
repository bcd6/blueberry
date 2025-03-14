import 'dart:convert';
import 'dart:io';
import 'package:blueberry/domain/album.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../domain/track.dart';
import '../domain/playlist.dart';

class FavState extends ChangeNotifier {
  static const String _favFileName = '~fav.json';
  static const String _favFolderPath = 'D:\\~\\album';
  Album _favAlbum = Album(
    folderPath: _favFolderPath,
    name: 'Favorites',
    coverPath: path.join(_favFolderPath, 'folder.jpg'),
    playlists: [],
  );

  Album get favAlbum => _favAlbum;
  String get _favFilePath => path.join(_favFolderPath, _favFileName);

  Future<void> loadFavorites() async {
    try {
      final file = File(_favFilePath);
      if (!await file.exists()) {
        debugPrint('No favorites file found, creating new one');
        return;
      }

      final content = await file.readAsString();
      _favAlbum = Album.fromJson(json.decode(content));
      debugPrint(
        'Loaded favorites with ${_favAlbum.playlists.length} playlists',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> saveFavorites() async {
    try {
      final file = File(_favFilePath);
      await file.writeAsString(json.encode(_favAlbum.toJson()));
      debugPrint(
        'Saved favorites with ${_favAlbum.playlists.length} playlists',
      );
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(Track track) {
    return _favAlbum.playlists.any(
      (playlist) => playlist.tracks.any((t) => t == track),
    );
  }

  Future<void> toggleFavorite(Track track) async {
    if (isFavorite(track)) {
      // Remove from favorites
      for (var playlist in _favAlbum.playlists) {
        playlist.tracks.removeWhere((t) => t == track);
      }
      // Remove empty playlists
      _favAlbum = Album(
        folderPath: _favAlbum.folderPath,
        name: _favAlbum.name,
        coverPath: _favAlbum.coverPath,
        playlists:
            _favAlbum.playlists.where((p) => p.tracks.isNotEmpty).toList(),
      );
      debugPrint('Removed from favorites: ${track.title}');
    } else {
      // Add to favorites
      final albumName = track.album ?? '';
      // Find existing playlist or create new one
      var targetPlaylist = _favAlbum.playlists.firstWhere(
        (p) => p.name == albumName,
        orElse: () {
          final newPlaylist = Playlist(name: albumName, tracks: []);
          _favAlbum = Album(
            folderPath: _favAlbum.folderPath,
            name: _favAlbum.name,
            coverPath: _favAlbum.coverPath,
            playlists: [..._favAlbum.playlists, newPlaylist],
          );
          return newPlaylist;
        },
      );

      // Add track to playlist
      if (!targetPlaylist.tracks.contains(track)) {
        targetPlaylist.tracks.add(track);
        debugPrint(
          'Added to favorites: ${track.title} in playlist: $albumName',
        );
      }
    }

    notifyListeners();
    await saveFavorites();
  }

  @override
  void dispose() {
    saveFavorites();
    super.dispose();
  }
}
