import 'package:blueberry/domain/playlist.dart';
import 'package:blueberry/feature/cue/cue_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import '../domain/config.dart';
import '../domain/album.dart';
import '../domain/track.dart';
import 'package:metadata_god/metadata_god.dart';

class AppState extends ChangeNotifier {
  Config? _config;
  final List<Album> _albums = [];
  static const String configPath = 'D:\\~\\album';
  static const String configFileName = '~.json';
  static const String coverFileName = 'folder.jpg';
  static const List<String> validFileTypes = [
    'flac',
    'ape',
    'mp3',
    'm4a',
    'aac',
    'ogg',
    'tak',
    'cue',
    'wav',
    'aiff',
    'alac',
    'wma',
    'opus',
    'dsd',
  ];

  Config? get config => _config;
  List<Album> get albums => _albums;

  // Config management
  String get _configFilePath => '$configPath\\$configFileName';

  Future<void> loadConfig() async {
    try {
      final file = File(_configFilePath);
      _config =
          await file.exists()
              ? Config.fromJson(json.decode(await file.readAsString()))
              : Config(folders: []);

      debugPrint('Config loaded: ${json.encode(_config?.toJson())}');
    } catch (e) {
      debugPrint('Error loading config: $e');
      _config = Config(folders: []);
    }
    notifyListeners();
  }

  // Album scanning
  Future<void> scanAlbums() async {
    _albums.clear();
    if (_config == null) {
      debugPrint('No config loaded, skipping album scan');
      return;
    }

    await _scanRootFolders();
    debugPrint('Scan completed. Found ${_albums.length} albums');
    notifyListeners();
  }

  static Future<Playlist?> loadRegularPlaylist(
    List<String> regularFiles,
  ) async {
    // Create regular tracks playlist with metadata
    final regularTracks = await Future.wait(
      regularFiles.map((f) => _createTrackFromFile(f)),
    );
    return regularTracks.isNotEmpty
        ? Playlist(name: '', tracks: regularTracks)
        : null;
  }

  static Future<List<Playlist>> loadCuePlaylists(List<String> cueFiles) async {
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

  Future<void> _scanRootFolders() async {
    for (final folder in _config!.folders) {
      try {
        final rootDirectory = Directory(folder.path);
        if (await rootDirectory.exists()) {
          await _scanDirectory(rootDirectory);
        } else {
          debugPrint('Skipping non-existent root directory: ${folder.path}');
        }
      } catch (e) {
        debugPrint('Error scanning root folder ${folder.path}: $e');
      }
    }
  }

  Future<void> _scanDirectory(Directory dir, {Album? parentAlbum}) async {
    try {
      final currentAlbum = await _processDirectory(dir, parentAlbum);
      await _scanSubdirectories(dir, currentAlbum);
    } catch (e) {
      debugPrint('Error scanning directory ${dir.path}: $e');
    }
  }

  Future<Album?> _processDirectory(Directory dir, Album? parentAlbum) async {
    final coverFile = File('${dir.path}\\$coverFileName');

    if (await coverFile.exists()) {
      final files = await _getValidFiles(dir);
      if (files.isNotEmpty) {
        // First get CUE files
        final cueFiles =
            files.where((f) => f.toLowerCase().endsWith('.cue')).toList();

        // Find files that match CUE file names
        final cueMatchFiles =
            files
                .where(
                  (f) => cueFiles.any(
                    (c) => f.toLowerCase().contains(
                      path.basenameWithoutExtension(c).toLowerCase(),
                    ),
                  ),
                )
                .toList();

        // Get audio files excluding CUE files and their matching audio files
        final audioFiles = files.where(
          (f) =>
              !f.toLowerCase().endsWith('.cue') && !cueMatchFiles.contains(f),
        );

        // Create album if there are any tracks or CUE files
        if (audioFiles.isNotEmpty || cueFiles.isNotEmpty) {
          final album = Album(
            folderPath: dir.path,
            name: dir.path.split('\\').last,
            coverPath: coverFile.path,
            regularFiles: audioFiles.toList(),
            cueFiles: cueFiles,
          );
          _albums.add(album);
          // debugPrint('''
          //   Found album: ${album.name}
          //   CUE files: ${cueFiles.length}
          //   Regular tracks: ${regularTracks.length}
          //   CUE matched files: ${cueMatchFiles.length}''');
          return album;
        }
      } else {
        debugPrint('Empty directory: ${dir.path}');
      }
    }
    return parentAlbum;
  }

  Future<void> _scanSubdirectories(Directory dir, Album? parentAlbum) async {
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final subDir = entity;
        if (!await _isEmptyDirectory(subDir)) {
          await _scanDirectory(subDir, parentAlbum: parentAlbum);
        }
      }
    }
  }

  // Utility methods

  Future<bool> _isEmptyDirectory(Directory dir) async {
    return await dir.list().isEmpty;
  }

  Future<List<String>> _getValidFiles(Directory dir) async {
    List<String> files = [];
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && _isValidFileType(entity.path)) {
          files.add(entity.path);
        }
      }
    } catch (e) {
      debugPrint('Error listing files in ${dir.path}: $e');
    }
    return files;
  }

  bool _isValidFileType(String path) {
    final extension = path.toLowerCase();
    return validFileTypes.any((type) => extension.endsWith(type));
  }

  static Future<Track> _createTrackFromFile(String filePath) async {
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

    duration ??= await getAudioDuration(filePath);

    return Track(
      path: filePath,
      title: title,
      album: album,
      performer: performer,
      duration: duration,
    );
  }

  static Future<Duration> getAudioDuration(String filePath) async {
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
      // debugPrint('Duration result: ${result.stdout}');

      return Duration(
        seconds: double.tryParse(result.stdout.trim())?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Error getting duration: $e');
      return Duration.zero;
    }
  }

  // State management
  void shuffleAlbums() {
    _albums.shuffle();
    debugPrint('Albums shuffled');
    notifyListeners();
  }
}
