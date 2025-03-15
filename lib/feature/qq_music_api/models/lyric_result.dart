import 'package:json_annotation/json_annotation.dart';

part 'lyric_result.g.dart';

@JsonSerializable()
class LyricResult {
  int code;
  String lyric;
  String trans;

  LyricResult({this.code = 0, this.lyric = '', this.trans = ''});

  factory LyricResult.fromJson(Map<String, dynamic> json) =>
      _$LyricResultFromJson(json);
  Map<String, dynamic> toJson() => _$LyricResultToJson(this);
}
