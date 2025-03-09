import 'dart:io';

import 'package:blueberry/feature/lyric/models/lyric.dart';
import 'package:blueberry/feature/lyric/models/lyric_line.dart';
import 'package:lyrics_parser/lyrics_parser.dart';

/// Parser for LRC files or LRC formatted strings.
class LrcLyricParser {
  Future<Lyric> parse(File file) async {
    final parser = LyricsParser.fromFile(file);
    // Must call ready before parser.
    await parser.ready();
    final result = await parser.parse();

    return Lyric(
      title: result.title,
      artist: result.artist,
      album: result.album,
      duration: Duration(milliseconds: result.millisecondLength!.toInt()),
      lines: generateLyricLineFromList(result.lyricList),
    );
  }

  List<LyricLine> generateLyricLineFromList(List lyricList) {
    List<LyricLine> ll = [];
    for (final lyric in lyricList) {
      ll.add(
        LyricLine(
          time: Duration(milliseconds: lyric.startTimeMillisecond!.toInt()),
          content: lyric.content,
        ),
      );
    }
    return ll;
  }
}
