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

    for (final folder in _config!.folders) {
      try {
        final rootDirectory = Directory(folder.path);
        if (!await rootDirectory.exists()) {
          debugPrint('Skipping non-existent root directory: ${folder.path}');
          continue;
        }

        // List all subdirectories in the root folder
        await for (final entity in rootDirectory.list()) {
          if (entity is Directory) {
            final subDir = entity;
            final coverFile = File('${subDir.path}\\cover.jpg');

            if (await coverFile.exists()) {
              final albumName = subDir.path.split('\\').last;
              _albums.add(
                Album(
                  path: subDir.path,
                  name: albumName,
                  coverPath: coverFile.path,
                ),
              );
              debugPrint('Found album: $albumName at ${subDir.path}');
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning root folder ${folder.path}: $e');
      }
    }

    debugPrint('Scan completed. Found ${_albums.length} albums');
    notifyListeners();
  }

  void shuffleAlbums() {
    _albums.shuffle();
    debugPrint('Albums shuffled using built-in shuffle');
    notifyListeners();
  }
}
