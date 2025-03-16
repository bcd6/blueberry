// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
  folderPath: json['folderPath'] as String,
  coverFilePath: json['coverFilePath'] as String,
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
  'coverFilePath': instance.coverFilePath,
  'regularFiles': instance.regularFiles,
  'cueFiles': instance.cueFiles,
};
