import 'dart:async';
import 'package:flutter/material.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';

class AudioWaveformStrip extends StatefulWidget {
  final int totalSeconds;
  final String? studentTranscript;
  final String? audioUrl;
  final bool? isPlaying;

  const AudioWaveformStrip({
    super.key,
    int? totalSeconds,
    int? durationSeconds,
    this.studentTranscript,
    this.audioUrl,
    this.isPlaying,
  }) : totalSeconds = durationSeconds ?? totalSeconds ?? 0;

  @override
  State<AudioWaveformStrip> createState() => _AudioWaveformStripState();
}

class _AudioWaveformStripState extends State<AudioWaveformStrip> {
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _playbackTimer;

  // Exact vertical waveform bar heights user likes, gently reduced for feed compactness
  static const List<double> _waveformHeights = [
    4, 8, 13, 7, 16, 10, 6, 14, 18, 11, 8, 17, 13, 7, 10, 15, 11, 6, 9, 13,
    17, 10, 7, 11, 14, 9, 6, 10, 13, 7
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying != null) {
      _isPlaying = widget.isPlaying!;
    }
  }

  @override
  void didUpdateWidget(AudioWaveformStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != null && widget.isPlaying != _isPlaying) {
      if (widget.isPlaying!) {
        _startPlayback();
      } else {
        _stopPlayback();
      }
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    if (_isPlaying) {
      NativeDeviceService.stopAudio();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = true);

    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      await NativeDeviceService.playAudio(widget.audioUrl!);
    }

    final totalMs = (widget.totalSeconds > 0 ? widget.totalSeconds : 30) * 1000;
    const intervalMs = 100;

    _playbackTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += (intervalMs / totalMs);
        if (_progress >= 1.0) {
          _progress = 0.0;
          _isPlaying = false;
          timer.cancel();
          NativeDeviceService.stopAudio();
        }
      });
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    NativeDeviceService.stopAudio();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotalSec = widget.totalSeconds > 0 ? widget.totalSeconds : 30;
    final elapsedSec = (effectiveTotalSec * _progress).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlipTheme.hairline, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Minimal tactile play button (compact 26x26)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: SlipTheme.carbon,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: SlipTheme.canvas,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Waveform scrubber bars with tap-to-seek
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final barWidth = constraints.maxWidth;
                    return GestureDetector(
                      onTapDown: (details) {
                        if (barWidth > 0) {
                          final localX = details.localPosition.dx;
                          final newProgress = (localX / barWidth).clamp(0.0, 1.0);
                          setState(() => _progress = newProgress);
                        }
                      },
                      child: SizedBox(
                        height: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_waveformHeights.length, (index) {
                            final isPlayed = (index / _waveformHeights.length) <= _progress;
                            return Container(
                              width: 2.0,
                              height: _waveformHeights[index],
                              decoration: BoxDecoration(
                                color: isPlayed ? SlipTheme.carbon : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Time label
              Text(
                '${_formatTime(elapsedSec)} / ${_formatTime(effectiveTotalSec)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: SlipTheme.steel,
                ),
              ),
            ],
          ),
          if (widget.studentTranscript != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                widget.studentTranscript!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 10.5,
                  color: SlipTheme.steel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
