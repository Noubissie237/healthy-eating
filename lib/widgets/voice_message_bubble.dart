import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioPath;
  final int duration;

  const VoiceMessageBubble({
    super.key,
    required this.audioPath,
    required this.duration,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  double _playbackProgress = 0;
  int _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _player.setSubscriptionDuration(const Duration(milliseconds: 100));
    _player.onProgress?.listen((event) {
      setState(() {
        _currentPosition = event.position.inSeconds;
        _playbackProgress =
            event.position.inMilliseconds / event.duration.inMilliseconds;
      });
    });
  }

  Future<void> _togglePlayback() async {
    if (!_isPlaying) {
      await _player.startPlayer(
        fromURI: widget.audioPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _playbackProgress = 0;
            _currentPosition = 0;
          });
        },
      );
    } else {
      await _player.stopPlayer();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlayback,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _playbackProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(
                    _isPlaying ? _currentPosition : widget.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }
}
