import 'lyric_line.dart';

class Lyric {
  /// Title of the media
  final String? title;

  /// Artist of the media
  final String? artist;

  /// Album of the media
  final String? album;

  /// Duration of the media
  final Duration? duration;

  /// Lines of the lyric
  final List<LyricLine> lines;

  Lyric({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.lines,
  });
}
