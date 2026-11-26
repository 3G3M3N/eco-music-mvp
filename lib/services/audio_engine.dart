import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AudioEngine extends ChangeNotifier {
  AudioPlayer? _playerInstance;
  final Map<String, Uint8List> _uploadedAudioBytes = {};

  String? _activeTrackId;
  bool _isPlaying = false;
  double _currentSeconds = 0.0;
  int _totalDurationSec = 60;
  Timer? _positionTicker;

  String? get activeTrackId => _activeTrackId;
  bool get isPlaying => _isPlaying;
  double get currentSeconds => _currentSeconds;
  int get currentSecondInt => _currentSeconds.floor();
  int get totalDurationSec => _totalDurationSec;

  AudioPlayer? get _player {
    if (_playerInstance != null) return _playerInstance;
    try {
      _playerInstance = AudioPlayer();
      _playerInstance!.onDurationChanged.listen((Duration d) {
        if (d.inSeconds > 0) {
          _totalDurationSec = d.inSeconds;
          notifyListeners();
        }
      });
      _playerInstance!.onPositionChanged.listen((Duration p) {
        _currentSeconds = p.inMilliseconds / 1000.0;
        notifyListeners();
      });
      _playerInstance!.onPlayerComplete.listen((_) {
        _currentSeconds = 0;
        _isPlaying = false;
        _stopTicker();
        notifyListeners();
      });
    } catch (_) {
      _playerInstance = null;
    }
    return _playerInstance;
  }

  void registerUploadedBytes(String trackId, Uint8List bytes) {
    _uploadedAudioBytes[trackId] = bytes;
  }

  bool isTrackPlaying(String trackId) =>
      _activeTrackId == trackId && _isPlaying;

  bool isTrackActive(String trackId) => _activeTrackId == trackId;

  int effectiveDurationForTrack(Track track) {
    if (_activeTrackId == track.id && _totalDurationSec > 0) {
      return _totalDurationSec;
    }
    return track.durationSec > 0 ? track.durationSec : 60;
  }

  double progressForTrack(Track track) {
    if (_activeTrackId != track.id) return 0.0;
    final dur = effectiveDurationForTrack(track);
    if (dur <= 0) return 0.0;
    return (_currentSeconds / dur).clamp(0.0, 1.0);
  }

  Future<void> togglePlay(Track track, {VoidCallback? onFirstPlay}) async {
    if (_activeTrackId == track.id) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume(track);
      }
      return;
    }

    await playTrack(track, onFirstPlay: onFirstPlay);
  }

  Future<void> playTrack(
    Track track, {
    double startAtSec = 0,
    VoidCallback? onFirstPlay,
  }) async {
    final bool isNewActivation = _activeTrackId != track.id;
    _activeTrackId = track.id;
    _totalDurationSec = track.durationSec > 0 ? track.durationSec : 60;
    _currentSeconds = startAtSec.clamp(0.0, _totalDurationSec.toDouble());
    _isPlaying = true;
    notifyListeners();

    if (isNewActivation && onFirstPlay != null) {
      onFirstPlay();
    }

    // Eğer parça YouTube / TikTok / Instagram linki ise arka planda yapay ses çalma;
    // sesi doğrudan kartın içindeki gerçek gömülü video oynatıcı (iframe) çalar!
    if (track.hasExternalLink) {
      try {
        await _playerInstance?.stop();
      } catch (_) {}
      _startTicker();
      return;
    }

    try {
      final player = _player;
      if (player == null) {
        _startTicker();
        return;
      }
      await player.stop();
      if (_uploadedAudioBytes.containsKey(track.id)) {
        await player.play(BytesSource(_uploadedAudioBytes[track.id]!));
      } else if (track.audioUrl.startsWith('http://') ||
          track.audioUrl.startsWith('https://')) {
        await player.play(UrlSource(track.audioUrl));
      } else {
        _startTicker();
      }
      if (startAtSec > 0) {
        await player
            .seek(Duration(milliseconds: (startAtSec * 1000).round()));
      }
    } catch (_) {
      _startTicker();
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    _stopTicker();
    notifyListeners();
    try {
      await _playerInstance?.pause();
    } catch (_) {}
  }

  Future<void> resume(Track track) async {
    _activeTrackId = track.id;
    _isPlaying = true;
    if (track.hasExternalLink || !_uploadedAudioBytes.containsKey(track.id)) {
      _startTicker();
    }
    notifyListeners();
    try {
      if (!track.hasExternalLink) {
        await _playerInstance?.resume();
      }
    } catch (_) {}
  }

  Future<void> seekToSecond(
    Track track,
    double second, {
    VoidCallback? onFirstPlay,
  }) async {
    if (_activeTrackId != track.id) {
      await playTrack(track, startAtSec: second, onFirstPlay: onFirstPlay);
      return;
    }
    final dur = effectiveDurationForTrack(track);
    _currentSeconds = second.clamp(0.0, dur.toDouble());
    notifyListeners();
    try {
      if (!track.hasExternalLink) {
        await _playerInstance
            ?.seek(Duration(milliseconds: (second * 1000).round()));
      }
    } catch (_) {}
  }

  void _startTicker() {
    _stopTicker();
    _positionTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_isPlaying) return;
      _currentSeconds += 0.25;
      if (_currentSeconds >= _totalDurationSec) {
        _currentSeconds = 0.0;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _positionTicker?.cancel();
    _positionTicker = null;
  }

  static String formatDuration(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopTicker();
    _playerInstance?.dispose();
    super.dispose();
  }
}
