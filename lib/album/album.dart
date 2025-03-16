import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final String folderPath;
  final String coverFilePath;
  final List<String> regularFiles;
  final List<String> cueFiles;

  Album({
    required this.folderPath,
    required this.coverFilePath,
    this.regularFiles = const [],
    this.cueFiles = const [],
  });

  String get folderName => folderPath.split('\\').last;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);
}
