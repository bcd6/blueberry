// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
  name: json['name'] as String,
  tracks:
      (json['tracks'] as List<dynamic>)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
  'name': instance.name,
  'tracks': instance.tracks,
};
