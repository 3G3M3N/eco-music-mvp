import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildPlatformIframe({
  required String viewId,
  required String embedUrl,
  required String originalUrl,
}) {
  return Container(
    color: const Color(0xFF0A0B0F),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.ondemand_video_rounded,
          color: Color(0xFF8B5CF6),
          size: 38,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final uri = Uri.tryParse(originalUrl);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Videoyu Aç'),
        ),
      ],
    ),
  );
}
