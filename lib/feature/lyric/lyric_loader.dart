import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class LyricLoader {
  static const _pythonScript = 'assets/scripts/fetch_lyrics.py';

  static String _sanitizeFilename(String filename) {
    // Windows invalid characters: \ / : * ? " < > |
    return filename
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String?> loadLyricContent(
    String trackPath,
    String trackTitle,
    String? album,
    String? performer,
  ) async {
    try {
      debugPrint('\n=== Looking for Lyrics ===');
      debugPrint('Track: $trackTitle');
      debugPrint('Album: $album');

      // Try local file first
      final localLyric = await _loadLocalLyric(trackPath, trackTitle);
      if (localLyric != null) {
        return localLyric;
      }

      // If local file not found, try remote API
      final remoteLyric = await _searchRemoteLyric(
        trackTitle,
        album,
        performer,
      );
      if (remoteLyric != null) {
        // Save remote lyric to local file
        await _saveLyricToLocal(trackPath, trackTitle, remoteLyric);
        return remoteLyric;
      }

      // Create empty LRC file if search failed
      debugPrint('Creating empty LRC file as placeholder');
      await _createEmptyLrcFile(trackPath, trackTitle, album, performer);
      return null;
    } catch (e) {
      debugPrint('Error in lyric loader: $e');
      return null;
    }
  }

  static Future<String?> _loadLocalLyric(
    String trackPath,
    String trackTitle,
  ) async {
    final directory = path.dirname(trackPath);
    final filename = path.basenameWithoutExtension(trackPath);
    final sanitizedTitle = _sanitizeFilename(trackTitle);
    final sanitizedFilename = _sanitizeFilename(filename);

    debugPrint('Checking local files...');
    debugPrint('Directory: $directory');

    // Try different filenames and extensions
    for (final name in [sanitizedTitle, sanitizedFilename]) {
      for (final ext in ['.lrc']) {
        final lyricPath = path.join(directory, '$name$ext');
        final lyricFile = File(lyricPath);

        debugPrint('Trying: $lyricPath');

        if (await lyricFile.exists()) {
          debugPrint('Found local lyric file!');

          // Try different encodings
          for (final encoding in [utf8, latin1, systemEncoding]) {
            try {
              final content = await lyricFile.readAsString(encoding: encoding);
              debugPrint('Successfully read with ${encoding.name}');
              return content;
            } catch (e) {
              debugPrint('Failed to read with ${encoding.name}: $e');
              continue;
            }
          }
        }
      }
    }

    debugPrint('No local lyric file found');
    return null;
  }

  static Future<String?> _searchRemoteLyric(
    String title,
    String? album,
    String? performer,
  ) async {
    try {
      debugPrint('\n=== Searching Lyrics using Python ===');
      debugPrint('Title: $title');
      debugPrint('Album: $album');
      debugPrint('Performer: $performer');

      final scriptPath = path.join(Directory.current.path, _pythonScript);

      debugPrint('Script path: $scriptPath');

      if (!File(scriptPath).existsSync()) {
        debugPrint('Error: Python script not found at $scriptPath');
        return null;
      }

      final result = await Process.run('python', [
        scriptPath,
        title,
        if (performer != null) performer,
      ]);

      if (result.exitCode == 0) {
        try {
          final json = jsonDecode(result.stdout as String);

          if (json['success'] == true) {
            debugPrint('Successfully fetched lyrics');
            return json['lyrics'] as String;
          } else {
            debugPrint('Python script error: ${json.toString()}');
          }
        } catch (e) {
          debugPrint('Error parsing Python output: $e');
          debugPrint('Output: ${result.stdout}');
        }
      } else {
        debugPrint('Python script failed: ${result.stderr}');
      }

      return null;
    } catch (e, stack) {
      debugPrint('Error running Python script: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  static Future<void> _saveLyricToLocal(
    String trackPath,
    String title,
    String content,
  ) async {
    try {
      final directory = path.dirname(trackPath);
      final sanitizedTitle = _sanitizeFilename(title);
      final lyricPath = path.join(directory, '$sanitizedTitle.lrc');

      debugPrint('Saving lyrics to: $lyricPath');

      final file = File(lyricPath);
      await file.writeAsString(content, encoding: utf8);

      debugPrint('Lyrics saved successfully');
    } catch (e) {
      debugPrint('Error saving lyrics: $e');
    }
  }

  static Future<void> _createEmptyLrcFile(
    String trackPath,
    String title,
    String? album,
    String? performer,
  ) async {
    try {
      final directory = path.dirname(trackPath);
      final sanitizedTitle = _sanitizeFilename(title);
      final lyricPath = path.join(directory, '$sanitizedTitle.lrc');

      final content = '''[00:00.00]''';

      debugPrint('Creating empty LRC at: $lyricPath');
      final file = File(lyricPath);
      await file.writeAsString(content, encoding: utf8);
      debugPrint('Empty LRC file created successfully');
    } catch (e) {
      debugPrint('Error creating empty LRC file: $e');
    }
  }
}
