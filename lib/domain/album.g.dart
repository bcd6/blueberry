// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
  folderPath: json['folderPath'] as String,
  name: json['name'] as String,
  coverPath: json['coverPath'] as String,
  playlists:
      (json['playlists'] as List<dynamic>?)
          ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  regularFiles:
      (json['regularFiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  cueFiles:
      (json['cueFiles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
  'folderPath': instance.folderPath,
  'name': instance.name,
  'coverPath': instance.coverPath,
  'playlists': instance.playlists,
  'regularFiles': instance.regularFiles,
  'cueFiles': instance.cueFiles,
};
