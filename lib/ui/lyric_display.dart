import 'package:flutter/material.dart';

class LyricDisplay extends StatefulWidget {
  const LyricDisplay({super.key});

  @override
  State<LyricDisplay> createState() => _LyricDisplayState();
}

class _LyricDisplayState extends State<LyricDisplay> {
  String _currentLyric = 'Lyrics will appear here';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLyrics();
  }

  Future<void> _initializeLyrics() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Add lyrics loading logic
      debugPrint('Initializing lyrics display');
    } catch (e) {
      debugPrint('Error loading lyrics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(16),
      child: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                  _currentLyric,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
      ),
    );
  }
}
