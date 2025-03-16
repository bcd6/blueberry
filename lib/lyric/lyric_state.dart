import 'package:blueberry/config/config.dart';
import 'package:blueberry/lyric/lyric_loader.dart';
import 'package:blueberry/lyric/lyric_parser.dart';
import 'package:blueberry/lyric/lyric_part.dart';
import 'package:blueberry/player/track.dart';
import 'package:flutter/foundation.dart';

class LyricState extends ChangeNotifier {
  List<LyricLine> _currentLyric = [];
  int _currentIndex = 0;
  int _currentPartIndex = 0;

  List<LyricLine> get currentLyric => _currentLyric;
  int get currentIndex => _currentIndex;
  int get currentPartIndex => _currentPartIndex;

  Future<void> load(Track track) async {
    final content = await LyricLoader.loadLyricContent(
      track.path,
      track.title,
      track.album,
      track.performer,
    );
    if (content != null) {
      debugPrint('Lyric content loaded: ${content.length} characters');
      final lyrics = LyricParser.parse(content);
      debugPrint('Parsed ${lyrics.length} lyric lines');

      if (lyrics.isNotEmpty) {
        debugPrint('First line: ${lyrics[0].fullText}');
        debugPrint('First timestamp: ${lyrics[0].startTime}');
      }

      _currentLyric = lyrics;
      _currentIndex = 0;
      _currentPartIndex = 0;
    } else {
      debugPrint('No lyrics found');
    }
    debugPrint('=== Lyrics Loading Complete ===\n');
    notifyListeners();
  }

  Config defaultConfig() {
    return Config(folders: [], coverFileName: '', favFilePath: '');
  }
}
