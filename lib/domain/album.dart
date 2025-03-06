class Album {
  final String path;
  final String name;
  final String coverPath;
  final List<String> files;
  final Map<String, Duration> trackDurations; // Add this field

  Album({
    required this.path,
    required this.name,
    required this.coverPath,
    required this.files,
    this.trackDurations = const {}, // Initialize empty
  });
}
