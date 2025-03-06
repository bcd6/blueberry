import 'dart:math';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../domain/config.dart';
import '../domain/album.dart';

class AppState extends ChangeNotifier {
  Config? _config;
  final List<Album> _albums = [];
  static const String configPath = 'D:\\~\\album';
  static const String configFileName = '~.json';
  static const String coverFileName = 'cover.jpg';
  static const List<String> validFileTypes = ['flac', 'ape', 'tak', 'cue'];

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
        final album = Album(
          folderPath: dir.path,
          name: dir.path.split('\\').last,
          coverPath: coverFile.path,
          files: files,
        );
        _albums.add(album);
        debugPrint('Found album: ${album.name} with ${files.length} files');
        return album;
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
      await for (final entity in dir.list()) {
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

  // State management
  void shuffleAlbums() {
    _albums.shuffle();
    debugPrint('Albums shuffled');
    notifyListeners();
  }
}
