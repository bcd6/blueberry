import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final String coverFilePath;
  final String? folderPath;
  final String? title;
  final List<String> regularFiles;
  final List<String> cueFiles;

  Album({
    required this.coverFilePath,
    this.folderPath,
    this.title,
    this.regularFiles = const [],
    this.cueFiles = const [],
  });

  String getAlbumTitle() => title ?? folderPath?.split('\\').last ?? '';

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);
}
