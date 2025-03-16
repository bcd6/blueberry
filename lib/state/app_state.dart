// import 'package:blueberry/player/playlist.dart';
// import 'package:blueberry/cue/cue_parser.dart';
// import 'package:blueberry/player/audio_player.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart' as path;
// import 'dart:io';
// import 'dart:convert';
// import '../config/config.dart';
// import '../album/album.dart';
// import '../player/track.dart';
// import 'package:metadata_god/metadata_god.dart';

// class AppState extends ChangeNotifier {
//   AppState();

//   Config? _config;
//   final List<Album> _albums = [];
//   static const String configPath = 'D:\\~\\album';
//   static const String configFileName = '~.json';
//   static const String coverFileName = 'folder.jpg';
//   static const List<String> validFileTypes = [
//     'flac',
//     'ape',
//     'mp3',
//     'm4a',
//     'aac',
//     'ogg',
//     'tak',
//     'cue',
//     'wav',
//     'aiff',
//     'alac',
//     'wma',
//     'opus',
//     'dsd',
//   ];

//   Config? get config => _config;
//   List<Album> get albums => _albums;

//   // Config management
//   String get _configFilePath => '$configPath\\$configFileName';

//   Future<void> loadConfig() async {
//     try {
//       final file = File(_configFilePath);
//       _config =
//           await file.exists()
//               ? Config.fromJson(json.decode(await file.readAsString()))
//               : Config(folders: []);

//       debugPrint('Config loaded: ${json.encode(_config?.toJson())}');
//     } catch (e) {
//       debugPrint('Error loading config: $e');
//       _config = Config(folders: []);
//     }

//     notifyListeners();
//   }

//   // Album scanning
//   Future<void> scanAlbums() async {
//     _albums.clear();
//     if (_config == null) {
//       debugPrint('No config loaded, skipping album scan');
//       return;
//     }

//     await _scanRootFolders();
//     debugPrint('Scan completed. Found ${_albums.length} albums');
//     notifyListeners();
//   }

//   Future<void> _scanRootFolders() async {
//     for (final folder in _config!.folders) {
//       try {
//         final rootDirectory = Directory(folder.path);
//         if (await rootDirectory.exists()) {
//           await _scanDirectory(rootDirectory, rootDirectory);
//         } else {
//           debugPrint('Skipping non-existent root directory: ${folder.path}');
//         }
//       } catch (e) {
//         debugPrint('Error scanning root folder ${folder.path}: $e');
//       }
//     }
//   }

//   Future<void> _scanDirectory(
//     Directory dir,
//     Directory root, {
//     Album? parentAlbum,
//   }) async {
//     try {
//       final currentAlbum = await _processDirectory(dir, root, parentAlbum);
//       await _scanSubdirectories(dir, root, currentAlbum);
//     } catch (e) {
//       debugPrint('Error scanning directory ${dir.path}: $e');
//     }
//   }

//   Future<Album?> _processDirectory(
//     Directory dir,
//     Directory root,
//     Album? parentAlbum,
//   ) async {
//     final coverFile = File('${dir.path}\\$coverFileName');

//     if (await coverFile.exists()) {
//       final files = await _getValidFiles(dir);
//       if (files.isNotEmpty) {
//         // First get CUE files
//         final cueFiles =
//             files.where((f) => f.toLowerCase().endsWith('.cue')).toList();

//         // Find files that match CUE file names
//         final cueMatchFiles =
//             files
//                 .where(
//                   (f) => cueFiles.any(
//                     (c) => f.toLowerCase().contains(
//                       path.basenameWithoutExtension(c).toLowerCase(),
//                     ),
//                   ),
//                 )
//                 .toList();

//         // Get audio files excluding CUE files and their matching audio files
//         final audioFiles = files.where(
//           (f) =>
//               !f.toLowerCase().endsWith('.cue') && !cueMatchFiles.contains(f),
//         );

//         // Create album if there are any tracks or CUE files
//         if (audioFiles.isNotEmpty || cueFiles.isNotEmpty) {
//           final album = Album(
//             folderPath: dir.path,
//             name: dir.path.split('\\').last,
//             coverPath: coverFile.path,
//             regularFiles: audioFiles.toList(),
//             cueFiles: cueFiles,
//           );
//           _albums.add(album);
//           // debugPrint('''
//           //   Found album: ${album.name}
//           //   CUE files: ${cueFiles.length}
//           //   Regular tracks: ${regularTracks.length}
//           //   CUE matched files: ${cueMatchFiles.length}''');
//           return album;
//         }
//       } else {
//         debugPrint('Empty cover directory: ${dir.path}');
//       }
//     } else {
//       // check if it is a directy sub folder of a root folder, if yes then print the name of the folder
//       if (dir.parent.path == root.path) {
//         debugPrint('No cover found in folder: ${dir.path}');
//         AudioService.openInExplorer(dir.path);
//       }
//     }
//     return parentAlbum;
//   }

//   Future<void> _scanSubdirectories(
//     Directory dir,
//     Directory root,
//     Album? parentAlbum,
//   ) async {
//     await for (final entity in dir.list()) {
//       if (entity is Directory) {
//         final subDir = entity;
//         if (!await _isEmptyDirectory(subDir)) {
//           await _scanDirectory(subDir, root, parentAlbum: parentAlbum);
//         } else {
//           debugPrint('No cover found in empty folder: ${subDir.path}');
//           AudioService.openInExplorer(dir.path);
//         }
//       }
//     }
//   }

//   // Utility methods

//   Future<bool> _isEmptyDirectory(Directory dir) async {
//     return await dir.list().isEmpty;
//   }

//   Future<List<String>> _getValidFiles(Directory dir) async {
//     List<String> files = [];
//     try {
//       await for (final entity in dir.list(recursive: true)) {
//         if (entity is File && _isValidFileType(entity.path)) {
//           files.add(entity.path);
//         }
//       }
//     } catch (e) {
//       debugPrint('Error listing files in ${dir.path}: $e');
//     }
//     return files;
//   }

//   bool _isValidFileType(String path) {
//     final extension = path.toLowerCase();
//     return validFileTypes.any((type) => extension.endsWith(type));
//   }

//   // State management
//   void shuffleAlbums() {
//     _albums.shuffle();
//     debugPrint('Albums shuffled');
//     notifyListeners();
//   }
// }
