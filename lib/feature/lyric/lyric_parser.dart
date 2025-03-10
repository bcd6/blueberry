import 'package:blueberry/feature/lyric/model/lyric_part.dart';
import 'package:flutter/foundation.dart';

// parse line
// 1. match the first n parts of the \[(\d{2}):(\d{2})\.(\d{2,3})\], if n > 1 then it's mutliple timestamp line,
// each match is a Line starttime, flatten it to multiple lines with same line parts
// 2. then match the line parts string, it could be like 藤[00:00.91]宫[00:01.83]ゆ[00:02.75]き [00:03.66]- [00:04.58]Words [00:05.50]Are[00:06.41] or <03:57.44> 信じた <03:58.23>   <03:59.37> (光と影の中)

// should support
// 1. line with timestamp [00:04.00]原曲：東方星蓮船「法界の火」
// 1. line with timestamp, 3 digits [00:36.889]我每天晚上在这里哪里也不想去
// 2. line with multiple timestamp [01:52.63][04:26.05][05:05.95]昼と夜の间で
// 3. line with chacater in betwen [00:00.00]藤[00:00.91]宫[00:01.83]ゆ[00:02.75]き [00:03.66]- [00:04.58]Words [00:05.50]Are[00:06.41]
// 4. line with chacater in betwen, and bracket [03:57.44] <03:57.44> 信じた <03:58.23>   <03:59.37> (光と影の中)
class LyricParser {
  // Two regex patterns for different character timing formats
  static final _textFirstRegex = RegExp(
    r'([^\[\]<>]+?)(?:\[(\d{2}):(\d{1,2})\.(\d{2,3})\])',
  );
  static final _timestampFirstRegex = RegExp(
    r'(?:\[(\d{2}):(\d{1,2})\.(\d{2,3})\]|\<(\d{2}):(\d{1,2})\.(\d{2,3})\>)\s*([^\[\]<>]*)',
  );
  static final _timestampRegex = RegExp(r'\[(\d{2}):(\d{1,2})\.(\d{2,3})\]');
  static final _multiTimestampLineRegex = RegExp(
    r'^(\[(\d{2}):(\d{1,2})\.(\d{2,3})\])+(.*)$',
  );

  static const emptyPartText = '♪';

  static List<LyricLine> parse(String content) {
    debugPrint('\n=== Parsing Lyrics ===');
    final allLines = <LyricLine>[];

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Step 1: Check for multiple timestamps at start
      final multiMatch = _multiTimestampLineRegex.firstMatch(trimmedLine);
      if (multiMatch != null) {
        final text = multiMatch.group(5)?.trim() ?? '';
        if (!text.contains('[') && !text.contains('<')) {
          // Get all timestamps
          final timestamps =
              _timestampRegex
                  .allMatches(trimmedLine)
                  .map(
                    (match) => _parseTimestamp(
                      match.group(1)!,
                      match.group(2)!,
                      match.group(3)!,
                    ),
                  )
                  .toList();

          // Create a line for each timestamp
          for (final timestamp in timestamps) {
            allLines.add(
              LyricLine([
                LyricPart(text.isEmpty ? emptyPartText : text, timestamp),
              ]),
            );
            debugPrint(
              'Multi-time line: "$text" @ ${_formatDuration(timestamp)}',
            );
          }
          continue;
        }
      } else {
        debugPrint('Single-time line: "$trimmedLine"');
      }

      // Step 2: Parse character-by-character with timestamps
      final parts = <LyricPart>[];
      var remainingLine = trimmedLine;
      debugPrint('Step 2 line: "$trimmedLine"');

      // Detect format based on first character
      final isTimestampFirst =
          remainingLine.startsWith('[') || remainingLine.startsWith('<');
      final regex = isTimestampFirst ? _timestampFirstRegex : _textFirstRegex;

      while (remainingLine.isNotEmpty) {
        final match = regex.firstMatch(remainingLine);
        if (match == null) {
          // Add remaining text to last part if exists
          if (parts.isNotEmpty && remainingLine.trim().isNotEmpty) {
            final lastPart = parts.removeLast();
            parts.add(
              LyricPart(
                '${lastPart.text}${remainingLine.trim()}',
                lastPart.timestamp,
              ),
            );
          }
          break;
        }

        if (isTimestampFirst) {
          final timestamp = _parseTimestamp(
            match.group(1) ?? match.group(4)!,
            match.group(2) ?? match.group(5)!,
            match.group(3) ?? match.group(6)!,
          );
          final text = match.group(7)?.trim() ?? '';
          if (text.isNotEmpty) {
            parts.add(LyricPart(text, timestamp));
            debugPrint(
              'Part (timestamp-first): "$text" @ ${_formatDuration(timestamp)}',
            );
          }
        } else {
          final text = match.group(1)?.trim() ?? '';
          final timestamp = _parseTimestamp(
            match.group(2)!,
            match.group(3)!,
            match.group(4)!,
          );
          if (text.isNotEmpty) {
            parts.add(LyricPart(text, timestamp));
            debugPrint(
              'Part (text-first): "$text" @ ${_formatDuration(timestamp)}',
            );
          }
        }

        remainingLine = remainingLine.substring(match.end);
      }

      if (parts.isNotEmpty) {
        allLines.add(LyricLine(parts));
        continue;
      }

      // Treat as plain text if no timestamps found
      allLines.add(LyricLine([LyricPart(trimmedLine, Duration.zero)]));
    }

    // Sort all lines by timestamp
    allLines.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Add empty line at start if needed
    if (allLines.isEmpty || allLines[0].startTime > Duration.zero) {
      allLines.insert(0, LyricLine([LyricPart(emptyPartText, Duration.zero)]));
    }

    return allLines;
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
