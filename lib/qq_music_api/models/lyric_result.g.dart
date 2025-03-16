// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyric_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LyricResult _$LyricResultFromJson(Map<String, dynamic> json) => LyricResult(
  code: (json['code'] as num?)?.toInt() ?? 0,
  lyric: json['lyric'] as String? ?? '',
  trans: json['trans'] as String? ?? '',
);

Map<String, dynamic> _$LyricResultToJson(LyricResult instance) =>
    <String, dynamic>{
      'code': instance.code,
      'lyric': instance.lyric,
      'trans': instance.trans,
    };
