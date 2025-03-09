import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class LyricLoader {
  static Future<String?> loadLyricContent(
    String trackPath,
    String trackTitle,
  ) async {
    try {
      debugPrint('\n=== Looking for Lyrics ===');
      final directory = path.dirname(trackPath);
      final filename = path.basenameWithoutExtension(trackPath);

      debugPrint('Directory: $directory');
      debugPrint('Base filename: $filename');

      // Try different lyric file extensions
      for (final ext in ['.lrc']) {
        final lyricPath = path.join(directory, '$trackTitle$ext');
        final lyricFile = File(lyricPath);

        debugPrint('Trying: $lyricPath');

        if (await lyricFile.exists()) {
          debugPrint('Found lyric file!');

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

      debugPrint('No lyric file found');
      return null;
    } catch (e) {
      debugPrint('Error in lyric loader: $e');
      return null;
    } finally {
      debugPrint('=== Lyric Search Complete ===\n');
    }
  }
}
