import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final String coverFilePath;
  final String? folderPath;
  final bool isFavAlbum;
  final List<String> regularFiles;
  final List<String> cueFiles;
  late String? _title;

  Album({
    required this.coverFilePath,
    this.folderPath,
    title,
    this.isFavAlbum = false,
    this.regularFiles = const [],
    this.cueFiles = const [],
  }) {
    _title = title;
  }

  String getAlbumTitle() => _title ?? folderPath?.split('\\').last ?? '';

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);
}
