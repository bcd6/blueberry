import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Map<String, Duration> _durationCache = {};

  AudioService() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      debugPrint('Player state: $state');
    });

    _player.onPositionChanged.listen((position) {
      debugPrint('Position: $position');
    });
  }

  Future<void> playFile(String filePath) async {
    try {
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('Error playing file: $e');
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.resume();
  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  void dispose() async {
    await _player.stop();
    await _player.dispose();
  }

  // Add getters for streams
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  Future<Duration?> getTrackDuration(String filePath) async {
    try {
      // Check cache first
      if (_durationCache.containsKey(filePath)) {
        return _durationCache[filePath];
      }

      // Use the main player to get duration
      await _player.setSource(DeviceFileSource(filePath));
      final duration = await _player.getDuration();

      if (duration != null) {
        _durationCache[filePath] = duration;
      }

      return duration;
    } catch (e) {
      debugPrint('Error getting duration for $filePath: $e');
      return null;
    }
  }
}
