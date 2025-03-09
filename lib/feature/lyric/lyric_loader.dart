import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class LyricLoader {
  static Future<String?> loadLyricContent(String trackPath) async {
    try {
      final directory = path.dirname(trackPath);
      final filename = path.basenameWithoutExtension(trackPath);

      // Try different lyric file extensions
      for (final ext in ['.lrc', '.txt']) {
        final lyricPath = path.join(directory, '$filename$ext');
        final lyricFile = File(lyricPath);

        if (await lyricFile.exists()) {
          debugPrint('Found lyric file: $lyricPath');
          // Try different encodings
          for (final encoding in [utf8, latin1, systemEncoding]) {
            try {
              return await lyricFile.readAsString(encoding: encoding);
            } catch (e) {
              debugPrint('Failed to read with ${encoding.name}: $e');
              continue;
            }
          }
        }
      }

      debugPrint('No lyric file found for: $filename');
      return null;
    } catch (e) {
      debugPrint('Error loading lyric file: $e');
      return null;
    }
  }
}
