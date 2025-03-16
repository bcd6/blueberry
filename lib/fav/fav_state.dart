import 'dart:convert';
import 'dart:io';
import 'package:blueberry/album/album.dart';
import 'package:blueberry/config/config_state.dart';
import 'package:blueberry/player/playlist.dart';
import 'package:blueberry/player/track.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FavState extends ChangeNotifier {
  final ConfigState _configState;
  final Album _favAlbum = Album(
    title: 'Favorites',
    coverFilePath: path.join(
      Directory.current.path,
      'assets',
      'images',
      'fav_cover.png',
    ),
  );
  List<Playlist> _favPlaylists = [];

  FavState(this._configState);

  Album get favAlbum => _favAlbum;
  List<Playlist> get favPlaylists => _favPlaylists;

  Future<void> init() async {
    try {
      final file = File(_configState.config.favFilePath);
      if (!await file.exists()) {
        debugPrint('No favorites file found, creating new one');
        // todo create a new file
        return;
      }
      final content = await file.readAsString();
      _favPlaylists = List<Playlist>.from(
        json.decode(content).map((x) => Playlist.fromJson(x)),
      );
      debugPrint('Loaded favorites with ${_favPlaylists.length} playlists');
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
    notifyListeners();
  }

  Future<void> persist() async {
    try {
      final file = File(_configState.config.favFilePath);
      await file.writeAsString(
        jsonEncode(_favPlaylists.map((x) => x.toJson()).toList()),
      );
      debugPrint('Saved favorites with ${_favPlaylists.length} playlists');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(Track track) {
    return _favPlaylists.any(
      (playlist) => playlist.tracks.any((t) => t == track),
    );
  }

  Future<void> toggleFavorite(Track track) async {
    if (isFavorite(track)) {
      // Create new playlists list with tracks removed
      final updatedPlaylists =
          _favPlaylists
              .map((playlist) {
                return Playlist(
                  name: playlist.name,
                  tracks: playlist.tracks.where((t) => t != track).toList(),
                );
              })
              .where((playlist) => playlist.tracks.isNotEmpty)
              .toList();

      // Update album with filtered playlists
      _favPlaylists = updatedPlaylists;
      debugPrint('Removed from favorites: ${track.title}');
    } else {
      // Add to favorites
      final albumName = track.album ?? 'Unknown Album';

      // Find existing playlist or create new one
      var targetPlaylist = _favPlaylists.firstWhere(
        (p) => p.name == albumName,
        orElse: () {
          final newPlaylist = Playlist(name: albumName, tracks: []);
          return newPlaylist;
        },
      );

      // Add track to playlist if not already present
      if (!targetPlaylist.tracks.contains(track)) {
        final updatedTracks = [...targetPlaylist.tracks, track];
        targetPlaylist = Playlist(name: albumName, tracks: updatedTracks);
        _favPlaylists = [
          targetPlaylist,
          ..._favPlaylists.where((p) => p.name != albumName),
        ];

        debugPrint(
          'Added to favorites: ${track.title} in playlist: $albumName',
        );
      }
    }

    notifyListeners();
    await persist();
  }

  @override
  void dispose() {
    persist();
    super.dispose();
  }
}
