import 'package:blueberry/feature/lyric/model/lyric_part.dart';

class LyricParser {
  static final _timeTagRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]');

  static List<LyricLine> parse(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    return lines
        .map(_parseLine)
        .where((line) => line.parts.isNotEmpty)
        .toList();
  }

  static LyricLine _parseLine(String line) {
    final parts = <LyricPart>[];
    var text = line;

    // Find all time tags
    final matches = _timeTagRegex.allMatches(line);
    var lastIndex = 0;

    for (final match in matches) {
      // Get the text before the time tag
      final char = text.substring(lastIndex, match.start).trim();
      if (char.isNotEmpty) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );

        parts.add(LyricPart(char, timestamp));
      }
      lastIndex = match.end;
    }

    // Add remaining text if any
    final remaining = text.substring(lastIndex).trim();
    if (remaining.isNotEmpty && parts.isNotEmpty) {
      parts.add(LyricPart(remaining, parts.last.timestamp));
    }

    return LyricLine(parts);
  }
}
