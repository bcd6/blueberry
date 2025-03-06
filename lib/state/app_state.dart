import 'dart:math';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../domain/config.dart';
import '../domain/album.dart';

class AppState extends ChangeNotifier {
  Config? _config;
  List<Album> _albums = [];
  static const String configPath = 'D:\\~\\album';
  static const String configFileName = '~.json';

  // Add file type constants
  static const List<String> validFileTypes = ['flac', 'tak', 'cue'];

  Config? get config => _config;
  List<Album> get albums => _albums;

  Future<void> loadConfig() async {
    try {
      final filePath = '$configPath\\$configFileName';
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _config = Config.fromJson(json.decode(jsonString));
      } else {
        // Create default config if file doesn't exist
        _config = Config(folders: []);
      }
      debugPrint('Config loaded: ${json.encode(_config?.toJson())}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading config: $e');
      _config = Config(folders: []);
    }
  }

  Future<void> scanAlbums() async {
    _albums.clear();

    if (_config == null) {
      debugPrint('No config loaded, skipping album scan');
      return;
    }

    // Start scanning from root folders
    for (final folder in _config!.folders) {
      try {
        final rootDirectory = Directory(folder.path);
        if (!await rootDirectory.exists()) {
          debugPrint('Skipping non-existent root directory: ${folder.path}');
          continue;
        }
        await scanDirectory(rootDirectory);
      } catch (e) {
        debugPrint('Error scanning root folder ${folder.path}: $e');
      }
    }

    debugPrint('Scan completed. Found ${_albums.length} albums');
    notifyListeners();
  }

  Future<bool> _hasValidFiles(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final extension = entity.path.toLowerCase();
          if (validFileTypes.any((type) => extension.endsWith(type))) {
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking files in ${dir.path}: $e');
    }
    return false;
  }

  Future<void> scanDirectory(Directory dir, {Album? parentAlbum}) async {
    try {
      final coverFile = File('${dir.path}\\cover.jpg');
      Album? currentAlbum = parentAlbum;

      // First check if directory has valid files
      final hasValidFiles = await _hasValidFiles(dir);

      // Only process if directory has cover.jpg AND valid files
      if (await coverFile.exists() && hasValidFiles) {
        final albumName = dir.path.split('\\').last;
        currentAlbum = Album(
          path: dir.path,
          name: albumName,
          coverPath: coverFile.path,
        );
        _albums.add(currentAlbum);
        debugPrint(
          'Found album with valid files: ${currentAlbum.name} at ${dir.path}',
        );
      }

      // Scan subdirectories
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final subDir = entity;
          final hasFiles = await subDir.list().isEmpty;

          if (!hasFiles) {
            if (currentAlbum != null) {
              // Check for valid files in subdirectory before adding
              final hasValidSubFiles = await _hasValidFiles(subDir);
              if (hasValidSubFiles) {
                final subAlbum = Album(
                  path: subDir.path,
                  name: currentAlbum.name,
                  coverPath: currentAlbum.coverPath,
                );
                _albums.add(subAlbum);
                debugPrint(
                  'Added subfolder with valid files: ${subDir.path} using parent album: ${currentAlbum.name}',
                );
              }
            }
            // Recursively scan subdirectory
            await scanDirectory(subDir, parentAlbum: currentAlbum);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${dir.path}: $e');
    }
  }

  void shuffleAlbums() {
    _albums.shuffle();
    debugPrint('Albums shuffled using built-in shuffle');
    notifyListeners();
  }
}
