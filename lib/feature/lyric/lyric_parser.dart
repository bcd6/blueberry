import 'package:blueberry/feature/lyric/model/lyric_part.dart';
import 'package:flutter/foundation.dart';

// should support
// 1. line with timestamp [00:04.00]原曲：東方星蓮船「法界の火」
// 1. line with timestamp, 3 digits [00:36.889]我每天晚上在这里哪里也不想去
// 2. line with multiple timestamp [01:52.63][04:26.05][05:05.95]昼と夜の间で
// 3. line with chacater in betwen [00:00.00]藤[00:00.91]宫[00:01.83]ゆ[00:02.75]き [00:03.66]- [00:04.58]Words [00:05.50]Are[00:06.41]
// 4. line with chacater in betwen, and bracket [03:57.44] <03:57.44> 信じた <03:58.23>   <03:59.37> (光と影の中)
class LyricParser {
  // Regex patterns for different formats
  static final _squareBracketRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
  static final _angleBracketRegex = RegExp(r'<(\d{2}):(\d{2})\.(\d{2,3})>');
  static final _characterTimeRegex = RegExp(
    r'([^\[\]<>]*?)(?:\[(\d{2}):(\d{2})\.(\d{2,3})\]|<(\d{2}):(\d{2})\.(\d{2,3})>)',
  );

  static List<LyricLine> parse(String content) {
    debugPrint('\n=== Parsing Lyrics ===');
    final allLines = <LyricLine>[];

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Check if it's a character-timed line
      if (_isCharacterTimedLine(trimmedLine)) {
        final parts = _parseCharacterTimedLine(trimmedLine);
        if (parts.isNotEmpty) {
          allLines.add(LyricLine(parts));
          continue;
        }
      }

      // Try parsing as multi-timestamp line
      final timestamps = _squareBracketRegex.allMatches(trimmedLine);
      if (timestamps.length > 1) {
        final text = trimmedLine.replaceAll(_squareBracketRegex, '').trim();
        for (final match in timestamps) {
          final timestamp = _parseTimestamp(
            match.group(1)!,
            match.group(2)!,
            match.group(3)!,
          );
          allLines.add(LyricLine([LyricPart(text, timestamp)]));
        }
        continue;
      }

      // Try single timestamp line
      final firstTimestamp = _squareBracketRegex.firstMatch(trimmedLine);
      if (firstTimestamp != null) {
        final text = trimmedLine.replaceAll(_squareBracketRegex, '').trim();
        final timestamp = _parseTimestamp(
          firstTimestamp.group(1)!,
          firstTimestamp.group(2)!,
          firstTimestamp.group(3)!,
        );
        allLines.add(LyricLine([LyricPart(text, timestamp)]));
        continue;
      }

      // Treat as plain text if no timestamps found
      allLines.add(LyricLine([LyricPart(trimmedLine, Duration.zero)]));
    }

    // Sort all lines by timestamp
    allLines.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Add empty line at start if needed
    if (allLines.isEmpty || allLines[0].startTime > Duration.zero) {
      allLines.insert(0, LyricLine([LyricPart('', Duration.zero)]));
    }

    return allLines;
  }

  static bool _isCharacterTimedLine(String line) {
    final parts = line.split(RegExp(r'(?:\[|\<)'));
    if (parts.length <= 1) return false;

    // Check if most parts have timestamps
    final withTimestamp =
        parts
            .where(
              (p) =>
                  p.contains(RegExp(r'\d{2}:\d{2}\.\d{2,3}\]')) ||
                  p.contains(RegExp(r'\d{2}:\d{2}\.\d{2,3}\>')),
            )
            .length;
    return withTimestamp > parts.length / 2;
  }

  static List<LyricPart> _parseCharacterTimedLine(String line) {
    final parts = <LyricPart>[];
    var match = _characterTimeRegex.firstMatch(line);
    var position = 0;

    while (match != null) {
      final text = match.group(1)?.trim() ?? '';
      final timestamp = _parseTimestamp(
        match.group(2) ?? match.group(5)!,
        match.group(3) ?? match.group(6)!,
        match.group(4) ?? match.group(7)!,
      );

      if (text.isNotEmpty) {
        parts.add(LyricPart(text, timestamp));
      }

      position = match.end;
      line = line.substring(position);
      match = _characterTimeRegex.firstMatch(line);
    }

    // Add remaining text if any
    final remaining = line.trim();
    if (remaining.isNotEmpty && parts.isNotEmpty) {
      parts.add(LyricPart(remaining, parts.last.timestamp));
    }

    return parts;
  }

  static Duration _parseTimestamp(
    String minutes,
    String seconds,
    String millisStr,
  ) {
    final millis =
        millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr);

    return Duration(
      minutes: int.parse(minutes),
      seconds: int.parse(seconds),
      milliseconds: millis,
    );
  }

  static String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'
        '.${(d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }
}
