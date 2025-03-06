class Album {
  final String folderPath;
  final String name;
  final String coverPath;
  final List<String> files;
  final Map<String, Duration> trackDurations; // Add this field

  Album({
    required this.folderPath,
    required this.name,
    required this.coverPath,
    required this.files,
    this.trackDurations = const {}, // Initialize empty
  });
}
