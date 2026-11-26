import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/audio_engine.dart';

class InteractiveWaveform extends StatelessWidget {
  final Track track;
  final List<TrackComment> comments;
  final bool isPlaying;
  final double currentSeconds;
  final Color accentColor;
  final ValueChanged<double> onSeekToSecond;
  final ValueChanged<TrackComment>? onCommentMarkerTap;

  const InteractiveWaveform({
    super.key,
    required this.track,
    required this.comments,
    required this.isPlaying,
    required this.currentSeconds,
    required this.accentColor,
    required this.onSeekToSecond,
    this.onCommentMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = track.durationSec > 0 ? track.durationSec : 45;
    final progress = (currentSeconds / duration).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                onSeekToSecond(ratio * duration);
              },
              onHorizontalDragUpdate: (details) {
                final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
                onSeekToSecond(ratio * duration);
              },
              child: SizedBox(
                height: 54,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      bottom: 14,
                      child: CustomPaint(
                        painter: _WaveformBarsPainter(
                          amplitudes: track.waveform,
                          progress: progress,
                          activeColor: accentColor,
                          inactiveColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    for (final c in comments)
                      _buildCommentPin(
                        comment: c,
                        maxWidth: width,
                        duration: duration,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AudioEngine.formatDuration(currentSeconds.floor()),
              style: TextStyle(
                color: isPlaying ? accentColor : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              AudioEngine.formatDuration(duration),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentPin({
    required TrackComment comment,
    required double maxWidth,
    required int duration,
  }) {
    final ratio = (comment.timestampSec / duration).clamp(0.02, 0.98);
    final left = (ratio * maxWidth) - 8;
    final isNearPlayhead = (currentSeconds - comment.timestampSec).abs() <= 1.2;

    return Positioned(
      left: left,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          onSeekToSecond(comment.timestampSec.toDouble());
          onCommentMarkerTap?.call(comment);
        },
        child: Tooltip(
          message:
              '${AudioEngine.formatDuration(comment.timestampSec)} • ${comment.content}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isNearPlayhead ? accentColor : const Color(0xFF1A1C26),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isNearPlayhead
                    ? Colors.white
                    : accentColor.withValues(alpha: 0.55),
                width: 0.8,
              ),
            ),
            child: Text(
              AudioEngine.formatDuration(comment.timestampSec),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformBarsPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformBarsPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final int count = amplitudes.length;
    final double totalBarSpace = size.width / count;
    final double barWidth = (totalBarSpace * 0.56).clamp(2.0, 5.5);
    final double centerY = size.height / 2;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double barRatio = i / count;
      final double amp = amplitudes[i].clamp(0.14, 1.0);
      final double barHeight = (amp * size.height).clamp(4.0, size.height);
      final double x = i * totalBarSpace + (totalBarSpace - barWidth) / 2;
      final double top = centerY - barHeight / 2;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(
        rrect,
        barRatio <= progress ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformBarsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}
