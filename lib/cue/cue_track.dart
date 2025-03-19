class CueTrack {
  final String title;
  final Duration start;
  final Duration? duration;
  final String performer;
  final int index;
  final String? isrc;
  final Duration? pregap;
  final String? audioFile; // Add this field

  CueTrack({
    required this.title,
    required this.start,
    this.duration,
    required this.performer,
    required this.index,
    this.isrc,
    this.pregap,
    this.audioFile, // Add this parameter
  });

  CueTrack copyWith({
    String? title,
    Duration? start,
    Duration? duration,
    String? performer,
    int? index,
    String? isrc,
    Duration? pregap,
    String? audioFile, // Add this parameter
  }) {
    return CueTrack(
      title: title ?? this.title,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      performer: performer ?? this.performer,
      index: index ?? this.index,
      isrc: isrc ?? this.isrc,
      pregap: pregap ?? this.pregap,
      audioFile: audioFile ?? this.audioFile, // Include in copyWith
    );
  }
}
