// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
  coverFilePath: json['coverFilePath'] as String,
  folderPath: json['folderPath'] as String?,
  title: json['title'] as String?,
  isFavAlbum: json['isFavAlbum'] as bool? ?? false,
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
  'coverFilePath': instance.coverFilePath,
  'folderPath': instance.folderPath,
  'title': instance.title,
  'isFavAlbum': instance.isFavAlbum,
  'regularFiles': instance.regularFiles,
  'cueFiles': instance.cueFiles,
};
