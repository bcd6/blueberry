class CueTrack {
  final String title;
  final Duration start;
  final Duration? duration;
  final String performer;
  final int index;
  final String? isrc;
  final Duration? pregap;

  CueTrack({
    required this.title,
    required this.start,
    this.duration,
    required this.performer,
    required this.index,
    this.isrc,
    this.pregap,
  });
}
