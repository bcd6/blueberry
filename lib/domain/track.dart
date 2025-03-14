import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';

@JsonSerializable()
class Track {
  final String path;
  final String title;
  final String? album;
  final String? performer;
  final Duration? duration;
  final Duration startOffset;
  final Map<String, String> metadata;
  final bool isCueTrack;

  Track({
    required this.path,
    required this.title,
    this.album = '',
    this.performer = '',
    this.duration,
    this.startOffset = Duration.zero,
    this.metadata = const {},
    this.isCueTrack = false,
  });

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
  Map<String, dynamic> toJson() => _$TrackToJson(this);

  String get fileName => path.split('\\').last;
}
