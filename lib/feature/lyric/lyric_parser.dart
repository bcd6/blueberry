import 'package:blueberry/feature/lyric/model/lyric_part.dart';
import 'package:flutter/foundation.dart';

// should support
// 1. line with timestamp [00:04.00]原曲：東方星蓮船「法界の火」
// 1. line with timestamp, 3 digits [00:36.889]我每天晚上在这里哪里也不想去
// 2. line with multiple timestamp [01:52.63][04:26.05][05:05.95]昼と夜の间で
// 3. line with chacater in betwen [00:00.00]藤[00:00.91]宫[00:01.83]ゆ[00:02.75]き [00:03.66]- [00:04.58]Words [00:05.50]Are[00:06.41]
// 4. line with chacater in betwen, and bracket [03:57.44] <03:57.44> 信じた <03:58.23>   <03:59.37> (光と影の中)
class LyricParser {
  // Unified timestamp regex for mixed brackets
  static final _timeTagRegex = RegExp(
    r'(?:\[(\d{2}):(\d{2})\.(\d{2,3})\]|\<(\d{2}):(\d{2})\.(\d{2,3})\>)\s*([^\[<]*)',
  );
  static const emptyPartText = '♪';

  static List<LyricLine> parse(String content) {
    debugPrint('\n=== Parsing Lyrics ===');
    final allLines = <LyricLine>[];

    for (final line in content.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Parse all timestamps and text parts
      final matches = _timeTagRegex.allMatches(trimmedLine);
      if (matches.isNotEmpty) {
        final parts = <LyricPart>[];

        for (final match in matches) {
          final timestamp = _parseTimestamp(match);
          final text = match.group(7)?.trim() ?? '';

          parts.add(LyricPart(text.isEmpty ? emptyPartText : text, timestamp));
          debugPrint(
            'Part: "${text.isEmpty ? emptyPartText : text}" @ ${_formatDuration(timestamp)}',
          );
        }

        // if part.text is empty, replace it by the next not empty part.text
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].text == emptyPartText) {
            for (var j = i + 1; j < parts.length; j++) {
              if (parts[j].text != emptyPartText) {
                parts[i] = LyricPart(parts[j].text, parts[i].timestamp);
                break;
              }
            }
          }
        }

        // if part.text is empty, and it is the last part, and not the only part, remove it
        if (parts.last.text == emptyPartText && parts.length > 1) {
          parts.removeLast();
        }

        if (parts.isNotEmpty) {
          // For lines with same text at different timestamps, create multiple lines
          if (parts.length > 1 && parts.every((p) => p.text == parts[0].text)) {
            for (final part in parts) {
              allLines.add(LyricLine([part]));
              debugPrint(
                'Multi-time line: "${part.text}" @ ${_formatDuration(part.timestamp)}',
              );
            }
          } else {
            // For character-timed lines, keep as one line
            allLines.add(LyricLine(parts));
            debugPrint('Character-timed line with ${parts.length} parts');
          }
          continue;
        }
      }

      // Treat as plain text if no timestamps found
      allLines.add(LyricLine([LyricPart(trimmedLine, Duration.zero)]));
      debugPrint('Plain text line: "$trimmedLine"');
    }

    // Sort all lines by timestamp
    allLines.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Add empty line at start if needed
    if (allLines.isEmpty || allLines[0].startTime > Duration.zero) {
      debugPrint('Adding empty line at start');
      allLines.insert(0, LyricLine([LyricPart(emptyPartText, Duration.zero)]));
    }

    return allLines;
  }

  static Duration _parseTimestamp(RegExpMatch match) {
    final minutes = int.parse(match.group(1) ?? match.group(4)!);
    final seconds = int.parse(match.group(2) ?? match.group(5)!);
    final millisStr = match.group(3) ?? match.group(6)!;

    final millis =
        millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr);

    return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
  }

  static String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'
        '.${(d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';
  }
}
