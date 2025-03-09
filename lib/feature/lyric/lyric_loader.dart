import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class LyricLoader {
  static const _baseUrl = 'https://www.lyrics.com';

  static Future<String?> loadLyricContent(
    String trackPath,
    String trackTitle,
    String? album,
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
      final remoteLyric = await _searchRemoteLyric(trackTitle, album);
      if (remoteLyric != null) {
        // Save remote lyric to local file
        await _saveLyricToLocal(trackPath, trackTitle, remoteLyric);
        return remoteLyric;
      }

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

    debugPrint('Checking local files...');
    debugPrint('Directory: $directory');

    // Try different filenames and extensions
    for (final name in [trackTitle, filename]) {
      for (final ext in ['.lrc', '.txt']) {
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

  static Future<String?> _searchRemoteLyric(String title, String? album) async {
    try {
      debugPrint('\n=== Searching Lyrics.com ===');
      debugPrint('Title: $title');
      debugPrint('Album: $album');

      // Search for song
      final searchQuery = Uri.encodeComponent('$title ${album ?? ''}');
      final searchUrl = '$_baseUrl/search/lyrics?q=$searchQuery';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'text/html'},
      );

      if (response.statusCode == 200) {
        // Find first lyric link in search results
        final linkMatch = RegExp(
          r'<a href="(/lyric/\d+/[^"]+)"[^>]*class="[^"]*title[^"]*"',
        ).firstMatch(response.body);

        if (linkMatch != null) {
          final lyricPath = linkMatch.group(1)!;
          debugPrint('Found lyric page: $lyricPath');

          // Get lyrics page
          final lyricsResponse = await http.get(
            Uri.parse('$_baseUrl$lyricPath'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          );

          if (lyricsResponse.statusCode == 200) {
            final lyrics = _extractLyricsFromHtml(lyricsResponse.body);
            if (lyrics != null) {
              debugPrint('Successfully extracted lyrics');
              return lyrics;
            }
          } else {
            debugPrint('Failed to get lyrics: ${lyricsResponse.statusCode}');
          }
        }
      } else {
        debugPrint('Failed to search: ${response.statusCode}');
      }

      debugPrint('No lyrics found on Lyrics.com');
      return null;
    } catch (e, stack) {
      debugPrint('Error searching lyrics: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  static String? _extractLyricsFromHtml(String html) {
    try {
      // Extract lyrics from pre tag with id="lyric-body-text"
      final lyricsMatch = RegExp(
        r'<pre[^>]*id="lyric-body-text"[^>]*>(.*?)</pre>',
        dotAll: true,
      ).firstMatch(html);

      if (lyricsMatch != null) {
        return lyricsMatch
            .group(1)
            ?.replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll('&nbsp;', ' ') // Fix spaces
            .replaceAll('&#x27;', "'") // Fix apostrophes
            .replaceAll('&quot;', '"') // Fix quotes
            .replaceAll('&amp;', '&') // Fix ampersands
            .trim();
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting lyrics: $e');
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
      final lyricPath = path.join(directory, '$title.lrc');

      debugPrint('Saving lyrics to: $lyricPath');

      final file = File(lyricPath);
      await file.writeAsString(content, encoding: utf8);

      debugPrint('Lyrics saved successfully');
    } catch (e) {
      debugPrint('Error saving lyrics: $e');
    }
  }
}
