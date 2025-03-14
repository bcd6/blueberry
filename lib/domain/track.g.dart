// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Track _$TrackFromJson(Map<String, dynamic> json) => Track(
  path: json['path'] as String,
  title: json['title'] as String,
  album: json['album'] as String? ?? '',
  albumCoverPath: json['albumCoverPath'] as String? ?? '',
  performer: json['performer'] as String? ?? '',
  duration:
      json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
  startOffset:
      json['startOffset'] == null
          ? Duration.zero
          : Duration(microseconds: (json['startOffset'] as num).toInt()),
  metadata:
      (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$TrackToJson(Track instance) => <String, dynamic>{
  'path': instance.path,
  'title': instance.title,
  'album': instance.album,
  'albumCoverPath': instance.albumCoverPath,
  'performer': instance.performer,
  'duration': instance.duration?.inMicroseconds,
  'startOffset': instance.startOffset.inMicroseconds,
  'metadata': instance.metadata,
};
