import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:lrc/lrc.dart';

class LyricLoader {
  static Future<Lrc> loadLyricByAudioFile(
    String audioFilePath,
    String audioTitle,
  ) async {
    try {
      final directory = path.dirname(audioFilePath);
      final filename = path.basenameWithoutExtension(audioTitle);

      debugPrint('Looking for lyrics directory: $directory');
      debugPrint('Looking for lyrics filename: $filename');

      // Try common lyric file extensions
      for (final ext in ['.lrc']) {
        final lyricPath = path.join(directory, '$filename$ext');
        final lyricFile = File(lyricPath);
        if (await lyricFile.exists()) {
          debugPrint('Found lyric file: $lyricPath');
          final content = await lyricFile.readAsString();
          final result = Lrc.parse(content);
          debugPrint('Parsed lyric file: $result');
          return result;
        }
      }
      debugPrint('No lyric file found for: $audioFilePath');
    } catch (e) {
      debugPrint('Error loading lyric file: $e');
    }
    return Lrc.parse('');
  }
}
