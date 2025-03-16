import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart'; // Required for generated code

@JsonSerializable()
class Config {
  final List<Folder> folders;
  final String coverFileName;
  final String favFilePath;
  final String? qqMusicCookie;

  Config({
    required this.folders,
    required this.coverFileName,
    required this.favFilePath,
    this.qqMusicCookie,
  });

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ConfigToJson(this); // Corrected method name
}

@JsonSerializable()
class Folder {
  final String path;

  Folder({required this.path});

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
  Map<String, dynamic> toJson() => _$FolderToJson(this);
}
