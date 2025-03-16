import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';

@JsonSerializable()
class Track {
  final String path;
  final String title;
  final String? album;
  final String? albumCoverPath;
  final String? performer;
  final Duration? duration;
  final Duration startOffset;

  Track({
    required this.path,
    required this.title,
    this.album = '',
    this.albumCoverPath = '',
    this.performer = '',
    this.duration,
    this.startOffset = Duration.zero,
  });

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
  Map<String, dynamic> toJson() => _$TrackToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track &&
        other.path == path &&
        other.startOffset == startOffset;
  }

  @override
  int get hashCode => Object.hash(path, startOffset);
}
