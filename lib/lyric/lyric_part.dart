class LyricPart {
  final String text;
  final Duration timestamp;

  const LyricPart(this.text, this.timestamp);
}

class LyricLine {
  final List<LyricPart> parts;
  final Duration startTime;

  LyricLine(this.parts)
    : startTime = parts.isEmpty ? Duration.zero : parts.first.timestamp;

  String get fullText => parts.map((p) => p.text).join();
}
