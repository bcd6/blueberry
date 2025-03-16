// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
  folders:
      (json['folders'] as List<dynamic>)
          .map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList(),
  coverFileName: json['coverFileName'] as String,
  favFilePath: json['favFilePath'] as String,
  qqMusicCookie: json['qqMusicCookie'] as String?,
);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
  'folders': instance.folders,
  'coverFileName': instance.coverFileName,
  'favFilePath': instance.favFilePath,
  'qqMusicCookie': instance.qqMusicCookie,
};

Folder _$FolderFromJson(Map<String, dynamic> json) =>
    Folder(path: json['path'] as String);

Map<String, dynamic> _$FolderToJson(Folder instance) => <String, dynamic>{
  'path': instance.path,
};
