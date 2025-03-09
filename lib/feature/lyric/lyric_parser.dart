import 'package:blueberry/feature/lyric/model/lyric_part.dart';
import 'package:flutter/foundation.dart';

class LyricParser {
  // Update the character timing regex pattern
  static final _characterTimeTagRegex = RegExp(
    r'(.*?)\[(\d{2}):(\d{2})\.(\d{2})\]',
  );
  static final _lineTimeTagRegex = RegExp(
    r'^\[(\d{2}):(\d{2})\.(\d{2})\](.+)$',
  );

  static List<LyricLine> parse(String content) {
    debugPrint('\n=== Parsing Lyrics ===');
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    final result =
        lines.map(_parseLine).where((line) => line.parts.isNotEmpty).toList();

    debugPrint('Parsed ${result.length} lines');
    return result;
  }

  static LyricLine _parseLine(String line) {
    debugPrint('\nParsing line: "$line"');

    // Try full line parsing first
    final lineMatch = _lineTimeTagRegex.firstMatch(line);
    if (lineMatch != null) {
      final minutes = int.parse(lineMatch.group(1)!);
      final seconds = int.parse(lineMatch.group(2)!);
      final centiseconds = int.parse(lineMatch.group(3)!);
      final text = lineMatch.group(4)!.trim();

      final timestamp = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: centiseconds * 10,
      );

      debugPrint('Line: "$text" @ ${_formatDuration(timestamp)}');
      return LyricLine([LyricPart(text, timestamp)]);
    }

    // Character-by-character parsing
    final parts = <LyricPart>[];
    var remainingLine = line;
    var match = _characterTimeTagRegex.firstMatch(remainingLine);

    while (match != null) {
      final char = match.group(1)!;
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final centiseconds = int.parse(match.group(4)!);

      final timestamp = Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: centiseconds * 10,
      );

      if (char.isNotEmpty) {
        parts.add(LyricPart(char, timestamp));
        debugPrint('Char: "$char" @ ${_formatDuration(timestamp)}');
      }

      // Update remaining line
      remainingLine = remainingLine.substring(match.end);
      match = _characterTimeTagRegex.firstMatch(remainingLine);
    }

    // Add any remaining text
    if (remainingLine.isNotEmpty && parts.isNotEmpty) {
      parts.add(LyricPart(remainingLine.trim(), parts.last.timestamp));
      debugPrint(
        'Remaining: "${remainingLine.trim()}" @ ${_formatDuration(parts.last.timestamp)}',
      );
    }

    return LyricLine(parts);
  }

  static String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'
        '.${(d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }
}
