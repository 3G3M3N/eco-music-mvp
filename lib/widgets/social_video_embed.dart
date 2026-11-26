import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_embed_stub.dart'
    if (dart.library.js_interop) 'social_embed_web.dart';

class SocialVideoEmbedPlayer extends StatelessWidget {
  final String trackId;
  final String externalUrl;
  final String? platform;

  const SocialVideoEmbedPlayer({
    super.key,
    required this.trackId,
    required this.externalUrl,
    this.platform,
  });

  static String? resolveEmbedUrl(String rawUrl) {
    final clean = rawUrl.trim();
    final uri = Uri.tryParse(clean);
    if (uri == null) return null;

    // 1. YouTube (watch?v=..., youtu.be/..., youtube.com/shorts/...)
    if (uri.host.contains('youtu.be') || uri.host.contains('youtube.com')) {
      String? videoId;
      if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          videoId = uri.pathSegments.first;
        }
      } else {
        if (uri.queryParameters.containsKey('v')) {
          videoId = uri.queryParameters['v'];
        } else if (uri.pathSegments.length >= 2 &&
            (uri.pathSegments[0] == 'shorts' ||
                uri.pathSegments[0] == 'embed' ||
                uri.pathSegments[0] == 'live')) {
          videoId = uri.pathSegments[1];
        }
      }
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1';
      }
    }

    // 2. TikTok (tiktok.com/@user/video/123456789)
    if (uri.host.contains('tiktok.com')) {
      final idx = uri.pathSegments.indexOf('video');
      if (idx != -1 && idx + 1 < uri.pathSegments.length) {
        final videoId = uri.pathSegments[idx + 1];
        return 'https://www.tiktok.com/embed/v2/$videoId';
      }
    }

    // 3. Instagram (instagram.com/reel/CODE/ veya instagram.com/p/CODE/)
    if (uri.host.contains('instagram.com') || uri.host.contains('instagr.am')) {
      for (int i = 0; i < uri.pathSegments.length - 1; i++) {
        final seg = uri.pathSegments[i];
        if (seg == 'reel' || seg == 'reels' || seg == 'p' || seg == 'tv') {
          final code = uri.pathSegments[i + 1];
          if (code.isNotEmpty) {
            return 'https://www.instagram.com/p/$code/embed';
          }
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final embedUrl = resolveEmbedUrl(externalUrl);

    if (embedUrl == null) {
      return Container(
        color: const Color(0xFF08090C),
        alignment: Alignment.center,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            final uri = Uri.tryParse(externalUrl);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Videoyu Oynat'),
        ),
      );
    }

    final viewId = 'eco-social-embed-$trackId-${embedUrl.hashCode}';

    return buildPlatformIframe(
      viewId: viewId,
      embedUrl: embedUrl,
      originalUrl: externalUrl,
    );
  }
}
