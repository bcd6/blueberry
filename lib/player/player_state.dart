import 'package:blueberry/album/album.dart';
import 'package:blueberry/config/config_state.dart';
import 'package:blueberry/cue/cue_parser.dart';
import 'package:blueberry/player/playlist.dart';
import 'package:blueberry/player/track.dart';
import 'package:blueberry/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as path;

class PlayerState extends ChangeNotifier {
  final ConfigState _configState;
  Album _currentAlbum = Album(coverFilePath: '');
  List<Playlist> _currentAlbumPlaylists = [];
  bool _currentTrackPlaying = false;
  Duration _currentPosition = Duration.zero;

  Playlist? _currentPlaylist;
  Track? _currentTrack;
  Stream<Duration>? _currentPositionStream;
  int? _currentPlaylistIndex;
  int? _currentTrackIndex;

  PlayerState(this._configState);

  Album get currentAlbum => _currentAlbum;
  List<Playlist> get currentAlbumPlaylists => _currentAlbumPlaylists;
  bool get currentTrackPlaying => _currentTrackPlaying;
  Duration get currentPosition => _currentPosition;

  Playlist? get currentPlaylist => _currentPlaylist;
  Track? get currentTrack => _currentTrack;
  Stream<Duration>? get currentPositionStream => _currentPositionStream;
  int? get currentPlaylistIndex => _currentPlaylistIndex;
  int? get currentTrackIndex => _currentTrackIndex;

  Future<void> setAlbum(Album album) async {
    _currentAlbum = album;
    _currentAlbumPlaylists = [];

    final regularPlaylist = await _loadRegularPlaylist(
      album.regularFiles,
      album.coverFilePath,
    );
    _currentAlbumPlaylists.addAll(regularPlaylist);

    final cuePlaylists = await _loadCuePlaylists(
      album.cueFiles,
      album.coverFilePath,
    );
    _currentAlbumPlaylists.addAll(cuePlaylists);

    debugPrint('SetAlbum ${_currentAlbumPlaylists.length} playlists');
    notifyListeners();
  }

  void setPosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setPlaying(bool flag) {
    _currentTrackPlaying = flag;
    notifyListeners();
  }

  void startNewCurrent(
    int playlistIndex,
    int trackIndex,
    Track track,
    Duration currentPosition,
    Stream<Duration> currentPositionStream,
    bool currentTrackPlaying,
  ) {
    _currentPlaylistIndex = playlistIndex;
    _currentTrackIndex = trackIndex;
    _currentTrack = track;
    _currentPosition = Duration.zero;
    _currentPositionStream = currentPositionStream;
    _currentTrackPlaying = true;
    notifyListeners();
  }

  void resetCurrent() {
    _currentPlaylistIndex = null;
    _currentTrackIndex = null;
    _currentTrack = null;
    _currentPosition = Duration.zero;
    _currentPositionStream = null;
    _currentTrackPlaying = false;
    notifyListeners();
  }

  static Future<List<Playlist>> _loadRegularPlaylist(
    List<String> regularFiles,
    String albumCoverPath,
  ) async {
    // Group files by parent folder
    final Map<String, List<String>> filesByFolder = {};

    for (final file in regularFiles) {
      final parentFolder = path.dirname(file);
      final folderName = path.basename(parentFolder);
      filesByFolder.putIfAbsent(folderName, () => []).add(file);
    }

    // Create playlists for each folder
    final List<Playlist> playlists = [];

    for (final entry in filesByFolder.entries) {
      final folderName = entry.key;
      final folderFiles = entry.value;

      // Create tracks for this folder's files
      final tracks = await Future.wait(
        folderFiles.map((f) => _createTrackFromFile(f, albumCoverPath)),
      );

      if (tracks.isNotEmpty) {
        playlists.add(Playlist(name: folderName, tracks: tracks));
      }
    }

    return playlists;
  }

  static Future<List<Playlist>> _loadCuePlaylists(
    List<String> cueFiles,
    String albumCoverPath,
  ) async {
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
                      album: cueSheet.title,
                      albumCoverPath: albumCoverPath,
                      performer: t.performer,
                      duration: t.duration,
                      startOffset: t.start,
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

  static Future<Track> _createTrackFromFile(
    String filePath,
    String albumCoverPath,
  ) async {
    String title = path.basenameWithoutExtension(filePath);
    String? album;
    String? performer;
    Duration? duration;
    try {
      final metadata = await MetadataGod.readMetadata(file: filePath);
      title = metadata.title?.isNotEmpty == true ? metadata.title! : title;
      album = metadata.album;
      performer = metadata.artist ?? '';
      duration = metadata.duration;
    } catch (e) {
      debugPrint('Error reading metadata from $filePath: $e');
    }

    duration ??= await Utils.getAudioDurationByFF(filePath);

    return Track(
      path: filePath,
      title: title,
      album: album,
      albumCoverPath: albumCoverPath,
      performer: performer,
      duration: duration,
    );
  }
}
