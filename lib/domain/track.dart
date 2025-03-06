class Track {
  final String path;
  final String title;
  final String performer;
  final Duration? duration;
  final Duration startOffset;
  final Map<String, String> metadata;

  Track({
    required this.path,
    required this.title,
    this.performer = '',
    this.duration,
    this.startOffset = Duration.zero,
    this.metadata = const {},
  });

  String get fileName => path.split('\\').last;
}
