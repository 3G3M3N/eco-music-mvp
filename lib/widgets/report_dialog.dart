import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';

Future<void> showReportContentDialog({
  required BuildContext context,
  required AppState appState,
  required String targetType,
  required String targetId,
  required String targetSummary,
  required String targetOwnerId,
}) async {
  String selectedReason = AppState.reportReasons.first;
  final detailsController = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111218),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            title: const Text(
              'İçeriği Bildir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetSummary,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  for (final reason in AppState.reportReasons)
                    RadioListTile<String>(
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: const Color(0xFF8B5CF6),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        reason,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedReason = val);
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Not ekle (opsiyonel)...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await appState.submitReport(
                    targetType: targetType,
                    targetId: targetId,
                    targetSummary: targetSummary,
                    targetOwnerId: targetOwnerId,
                    reason: selectedReason,
                    details: detailsController.text,
                  );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bildiriminiz incelenmek üzere alındı.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Bildir'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Instagram Story/Reels, TikTok ve YouTube'a Aktarım / Paylaşım Penceresi
Future<void> showSocialShareStudioSheet({
  required BuildContext context,
  required Track track,
  required AppUser artist,
  required AppState appState,
}) async {
  final themePreset = MyspaceThemePreset.fromId(artist.themeGradient);
  final shareUrl = track.hasExternalLink
      ? track.externalUrl!
      : 'https://eco.fm/@${artist.username}/${track.id}';
  final caption =
      '${track.title} — @${artist.username} (${track.genre}) ${track.tags.join(" ")} #eco\n$shareUrl';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E0F14),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instagram, TikTok & YouTube\'a Aktar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 9:16 Dikey Story / Reels / TikTok Kart Önizlemesi
            Center(
              child: Container(
                width: 210,
                height: 290,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themePreset.accentColor.withValues(alpha: 0.45),
                      ...themePreset.gradientColors,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: themePreset.accentColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'eco.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            track.genre,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        UserAvatar(
                          user: artist,
                          appState: appState,
                          radius: 34,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          track.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@${artist.username}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 13,
                            color: themePreset.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'eco.fm/@${artist.username}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hızlı Platform Aktarım Butonları
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    context: ctx,
                    label: 'Instagram Story / Reels',
                    color: const Color(0xFFE1306C),
                    icon: Icons.camera_alt_outlined,
                    copyPayload: caption,
                    toast:
                        'Instagram Story/Reels paylaşım kartı ve bağlantı panoya kopyalandı!',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildExportButton(
                    context: ctx,
                    label: 'TikTok\'a Aktar',
                    color: const Color(0xFF00F2FE),
                    icon: Icons.music_video_outlined,
                    copyPayload: caption,
                    toast: 'TikTok video açıklaması ve eco linki kopyalandı!',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bağlantı kopyalandı: $shareUrl'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.link_rounded, size: 17),
              label: Text(
                track.hasExternalLink
                    ? 'Orijinal Video Linkini Kopyala'
                    : 'eco Paylaşım Linkini Kopyala',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildExportButton({
  required BuildContext context,
  required String label,
  required Color color,
  required IconData icon,
  required String copyPayload,
  required String toast,
}) {
  return FilledButton.tonalIcon(
    style: FilledButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.16),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    ),
    onPressed: () async {
      await Clipboard.setData(ClipboardData(text: copyPayload));
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toast),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    },
    icon: Icon(icon, size: 16, color: color),
    label: Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
    ),
  );
}

/// TikTok / Instagram / YouTube Sosyal Platform Rozeti
class SocialPlatformBadge extends StatelessWidget {
  final String platform; // 'tiktok' | 'instagram' | 'youtube' | 'external'
  const SocialPlatformBadge({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final IconData icon;

    switch (platform) {
      case 'tiktok':
        label = 'TikTok';
        color = const Color(0xFF00F2FE);
        icon = Icons.music_note_rounded;
        break;
      case 'instagram':
        label = 'Instagram Reels';
        color = const Color(0xFFE1306C);
        icon = Icons.camera_alt_outlined;
        break;
      case 'youtube':
        label = 'YouTube';
        color = const Color(0xFFFF0033);
        icon = Icons.play_circle_outline_rounded;
        break;
      default:
        label = 'Sosyal Video';
        color = const Color(0xFF8B5CF6);
        icon = Icons.link_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final AppState appState;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    required this.appState,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = appState.getAvatarBytes(user.id);
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: const Color(0xFF1C1D26),
      );
    }
    if (user.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.avatarUrl),
        backgroundColor: const Color(0xFF1C1D26),
      );
    }
    final initial = user.displayName.isNotEmpty
        ? user.displayName.characters.first.toUpperCase()
        : user.username.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF232533),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

class EarlySupporterBadge extends StatelessWidget {
  final bool compact;
  const EarlySupporterBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 10 : 11,
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(width: 3),
          Text(
            'Early Supporter',
            style: TextStyle(
              color: const Color(0xFFFBBF24),
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class OpenToCollabBadge extends StatelessWidget {
  final bool compact;
  const OpenToCollabBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Collab Açık',
            style: TextStyle(
              color: const Color(0xFF34D399),
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
