import 'package:blueberry/album/album.dart';
import 'package:blueberry/config/config_state.dart';
import 'package:blueberry/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class AlbumState extends ChangeNotifier {
  final ConfigState _configState;
  final List<String> _validFileTypes = [
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
    'tta',
  ];
  List<Album> _albums = [];

  AlbumState(this._configState);

  List<Album> get albums => _albums;

  // Album scanning
  Future<void> init() async {
    _albums.clear();
    await _scanConfigFolders();
    _albums.sort(
      (a, b) =>
          Utils.windowsExplorerSort(a.folderPath ?? '', b.folderPath ?? ''),
    );
    _albums = _albums.reversed.toList();
    debugPrint('Scan completed. Found ${_albums.length} albums');
    notifyListeners();
  }

  // State management
  void shuffleAlbums() {
    _albums.shuffle();
    debugPrint('Albums shuffled');
    notifyListeners();
  }

  // Filtering
  List<Album> filterAlbums(String filterText) {
    if (filterText.isEmpty) {
      return _albums;
    }

    final lowerFilter = filterText.toLowerCase();
    return _albums.where((album) {
      // Check folder path
      if (album.folderPath != null &&
          album.folderPath!.toLowerCase().contains(lowerFilter)) {
        return true;
      }

      // Check regular files
      for (final file in album.regularFiles) {
        if (file.toLowerCase().contains(lowerFilter)) {
          return true;
        }
      }

      // Check cue files
      for (final file in album.cueFiles) {
        if (file.toLowerCase().contains(lowerFilter)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  Future<void> _scanConfigFolders() async {
    for (final folder in _configState.config.folders) {
      try {
        final rootDirectory = Directory(folder.path);
        if (await rootDirectory.exists()) {
          await _scanDirectory(rootDirectory, rootDirectory);
        } else {
          debugPrint('Skipping non-existent root directory: ${folder.path}');
        }
      } catch (e) {
        debugPrint('Error scanning root folder ${folder.path}: $e');
      }
    }
  }

  Future<void> _scanDirectory(
    Directory dir,
    Directory root, {
    Album? parentAlbum,
  }) async {
    try {
      final currentAlbum = await _processDirectory(dir, root, parentAlbum);
      await _scanSubdirectories(dir, root, currentAlbum);
    } catch (e) {
      debugPrint('Error scanning directory ${dir.path}: $e');
    }
  }

  Future<Album?> _processDirectory(
    Directory dir,
    Directory root,
    Album? parentAlbum,
  ) async {
    final coverFile = File('${dir.path}\\${_configState.config.coverFileName}');
    if (await coverFile.exists()) {
      final files = await _getValidFiles(dir);
      if (files.isNotEmpty) {
        // First get cue files
        final cueFiles =
            files.where((f) => f.toLowerCase().endsWith('.cue')).toList();

        // Find files that match cue file names
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

        // Get audio files excluding cue files and audio files that match cue files
        final audioFiles = files.where(
          (f) =>
              !f.toLowerCase().endsWith('.cue') && !cueMatchFiles.contains(f),
        );

        // Create album if there are any tracks or CUE files
        if (audioFiles.isNotEmpty || cueFiles.isNotEmpty) {
          final album = Album(
            coverFilePath: coverFile.path,
            folderPath: dir.path,
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
        debugPrint('Empty cover directory: ${dir.path}');
        Utils.openInExplorer(dir.path);
      }
    } else {
      // check if it is a directy sub folder of a root folder, if yes then print the name of the folder
      if (dir.parent.path == root.path) {
        debugPrint('No cover found in folder: ${dir.path}');
        Utils.openInExplorer(dir.path);
      }
    }
    return parentAlbum;
  }

  Future<void> _scanSubdirectories(
    Directory dir,
    Directory root,
    Album? parentAlbum,
  ) async {
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final subDir = entity;
        if (!await _isEmptyDirectory(subDir)) {
          await _scanDirectory(subDir, root, parentAlbum: parentAlbum);
        } else {
          debugPrint('No cover found in empty folder: ${subDir.path}');
          Utils.openInExplorer(dir.path);
        }
      }
    }
  }

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
    return _validFileTypes.any((type) => extension.endsWith(type));
  }
}
