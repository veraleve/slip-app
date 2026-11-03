import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class AudioWaveformStrip extends StatefulWidget {
  final int totalSeconds;
  final String? studentTranscript;
  final bool? isPlaying;

  const AudioWaveformStrip({
    super.key,
    int? totalSeconds,
    int? durationSeconds,
    this.studentTranscript,
    this.isPlaying,
  }) : totalSeconds = durationSeconds ?? totalSeconds ?? 0;

  @override
  State<AudioWaveformStrip> createState() => _AudioWaveformStripState();
}

class _AudioWaveformStripState extends State<AudioWaveformStrip> {
  bool _isPlaying = false;
  double _progress = 0.35; // Mock active playback progress

  static const List<double> _waveformHeights = [
    6, 12, 18, 10, 22, 14, 8, 20, 26, 16, 12, 24, 18, 10, 14, 22, 16, 8, 12, 18,
    24, 14, 10, 16, 20, 12, 8, 14, 18, 10
  ];

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSec = (widget.totalSeconds * _progress).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Minimal tactile play button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: SlipTheme.carbon,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: SlipTheme.canvas,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Waveform scrubber bars
            Expanded(
              child: SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_waveformHeights.length, (index) {
                    final isPlayed =
                        index / _waveformHeights.length <= _progress;
                    return Container(
                      width: 2.5,
                      height: _waveformHeights[index],
                      decoration: BoxDecoration(
                        color: isPlayed ? SlipTheme.carbon : SlipTheme.hairline,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Timestamp
            Text(
              '${_formatTime(elapsedSec)} / ${_formatTime(widget.totalSeconds)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SlipTheme.carbon,
                  ),
            ),
          ],
        ),
        if (widget.studentTranscript != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.studentTranscript!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
          ),
        ],
      ],
    );
  }
}
