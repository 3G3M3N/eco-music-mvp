import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/interactive_waveform.dart';
import '../widgets/report_dialog.dart';
import '../widgets/social_video_embed.dart';

class MyspaceProfileScreen extends StatelessWidget {
  final AppState appState;
  final String viewedUserId;
  final VoidCallback? onBackToOwnProfile;
  final void Function(AppUser artist, {Track? referenceTrack}) onStartCollabChat;
  final VoidCallback? onOpenStandaloneAdmin;

  const MyspaceProfileScreen({
    super.key,
    required this.appState,
    required this.viewedUserId,
    this.onBackToOwnProfile,
    required this.onStartCollabChat,
    this.onOpenStandaloneAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final user = appState.getUserById(viewedUserId) ?? appState.currentUser;
    if (user == null) return const SizedBox.shrink();

    final me = appState.currentUser;
    final isOwnProfile = me != null && me.id == user.id;
    final themePreset = MyspaceThemePreset.fromId(user.themeGradient);
    final userTracks = appState.tracksForUser(user.id);
    final Track? pinnedTrack = appState.getTrackById(user.pinnedTrackId) ??
        (userTracks.isNotEmpty ? userTracks.first : null);
    final isFollowing = appState.isFollowing(user.id);
    final isEarlySupporterOfThisArtist = me != null &&
        appState.isEarlySupporterOf(followerId: me.id, artistId: user.id);
    final earlyBadgesEarnedCount = appState.earlySupporterCountForUser(user.id);
    final combinedTags = user.combinedTags;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themePreset.gradientColors,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isOwnProfile && onBackToOwnProfile != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onBackToOwnProfile,
                        icon: const Icon(Icons.arrow_back_rounded, size: 17),
                        label: const Text(
                          'Geri',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),

                  // 1. Sleek Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0F14).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themePreset.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UserAvatar(
                              user: user,
                              appState: appState,
                              radius: 34,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (isEarlySupporterOfThisArtist ||
                                          earlyBadgesEarnedCount > 0)
                                        const EarlySupporterBadge(
                                            compact: true),
                                      if (user.isOpenToCollab)
                                        const OpenToCollabBadge(compact: true),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '@${user.username}  •  ${user.followerCount} takipçi  •  ${userTracks.length} kayıt',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwnProfile)
                              IconButton(
                                tooltip: 'Odayı ve Profili Düzenle',
                                onPressed: () =>
                                    _showEditRoomSheet(context, user),
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),

                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],

                        if (combinedTags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final style in user.musicStyles)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themePreset.accentColor
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: themePreset.accentColor
                                          .withValues(alpha: 0.45),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    style,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              for (final role in user.roles)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    role,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        if (isOwnProfile)
                          Row(
                            children: [
                              for (final preset in MyspaceThemePreset.presets)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => appState.updateMyspaceProfile(
                                      themeGradient: preset.id,
                                    ),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: preset.accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: preset.id == user.themeGradient
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (user.isAdmin &&
                                  onOpenStandaloneAdmin != null)
                                TextButton.icon(
                                  onPressed: onOpenStandaloneAdmin,
                                  icon: const Icon(
                                    Icons.shield_outlined,
                                    size: 15,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  label: const Text(
                                    'Moderasyon',
                                    style: TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () => appState.signOut(),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 15,
                                  color: Colors.white54,
                                ),
                                label: const Text(
                                  'Çıkış',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isFollowing
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white,
                                    foregroundColor: isFollowing
                                        ? Colors.white
                                        : Colors.black,
                                    minimumSize: const Size(0, 38),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () =>
                                      appState.toggleFollow(user.id),
                                  child: Text(
                                    isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: themePreset.accentColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 38),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => onStartCollabChat(
                                    user,
                                    referenceTrack: pinnedTrack,
                                  ),
                                  icon: const Icon(
                                    Icons.handshake_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'İş Birliği / Mesaj',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.white54,
                                ),
                                color: const Color(0xFF161821),
                                onSelected: (val) async {
                                  if (val == 'block') {
                                    await appState.blockUser(user.id);
                                    onBackToOwnProfile?.call();
                                  } else if (val == 'report') {
                                    await showReportContentDialog(
                                      context: context,
                                      appState: appState,
                                      targetType: 'user',
                                      targetId: user.id,
                                      targetSummary: '@${user.username}',
                                      targetOwnerId: user.id,
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'report',
                                    child: Text(
                                      'Hesabı Bildir',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'block',
                                    child: Text(
                                      'Kullanıcıyı Engelle',
                                      style: TextStyle(
                                        color: Color(0xFFF43F5E),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // 2. Pinned Track (İmza Parça)
                  if (pinnedTrack != null) ...[
                    const SizedBox(height: 16),
                    _buildPinnedTrackCard(
                      context: context,
                      artist: user,
                      pinnedTrack: pinnedTrack,
                      themePreset: themePreset,
                    ),
                  ],

                  // 3. Track List
                  const SizedBox(height: 20),
                  Text(
                    'KAYITLAR (${userTracks.length})',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userTracks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0F14).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Henüz paylaşılan kayıt yok.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12.5),
                      ),
                    )
                  else
                    for (final track in userTracks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildTrackRow(
                          context: context,
                          artist: user,
                          track: track,
                          isPinned: pinnedTrack?.id == track.id,
                          isOwnProfile: isOwnProfile,
                          themePreset: themePreset,
                        ),
                      ),

                  if (isOwnProfile && appState.blockedUserIds.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: appState.blockedUserIds.map((blockedId) {
                        final blockedUser = appState.getUserById(blockedId);
                        return Chip(
                          backgroundColor: const Color(0xFF161821),
                          label: Text(
                            'Engelli: @${blockedUser?.username ?? blockedId}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                          onDeleted: () => appState.unblockUser(blockedId),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedTrackCard({
    required BuildContext context,
    required AppUser artist,
    required Track pinnedTrack,
    required MyspaceThemePreset themePreset,
  }) {
    final comments = appState.commentsForTrack(pinnedTrack.id);

    return ListenableBuilder(
      listenable: appState.audioEngine,
      builder: (context, _) {
        final audio = appState.audioEngine;
        final isPlaying = audio.isTrackPlaying(pinnedTrack.id);
        final isActive = audio.isTrackActive(pinnedTrack.id);
        final currentSec = isActive ? audio.currentSeconds : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F14).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: themePreset.accentColor.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.push_pin_rounded,
                    color: themePreset.accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'İMZA PARÇA',
                    style: TextStyle(
                      color: themePreset.accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (pinnedTrack.externalPlatform != null) ...[
                    const SizedBox(width: 8),
                    SocialPlatformBadge(
                      platform: pinnedTrack.externalPlatform!,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${pinnedTrack.playCount} dinlenme',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Instagram / TikTok\'a Aktar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showSocialShareStudioSheet(
                      context: context,
                      track: pinnedTrack,
                      artist: artist,
                      appState: appState,
                    ),
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pinnedTrack.hasExternalLink && isPlaying) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: SocialVideoEmbedPlayer(
                      trackId: 'pinned_${pinnedTrack.id}',
                      externalUrl: pinnedTrack.externalUrl!,
                      platform: pinnedTrack.externalPlatform,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  GestureDetector(
                    onTap: () => audio.togglePlay(
                      pinnedTrack,
                      onFirstPlay: () =>
                          appState.incrementPlayCount(pinnedTrack.id),
                    ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPlaying
                            ? Colors.white
                            : themePreset.accentColor,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isPlaying
                            ? const Color(0xFF050507)
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pinnedTrack.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          pinnedTrack.genre,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!pinnedTrack.hasExternalLink)
                InteractiveWaveform(
                  track: pinnedTrack,
                  comments: comments,
                  isPlaying: isPlaying,
                  currentSeconds: currentSec,
                  accentColor: themePreset.accentColor,
                  onSeekToSecond: (sec) {
                    audio.seekToSecond(
                      pinnedTrack,
                      sec,
                      onFirstPlay: () =>
                          appState.incrementPlayCount(pinnedTrack.id),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackRow({
    required BuildContext context,
    required AppUser artist,
    required Track track,
    required bool isPinned,
    required bool isOwnProfile,
    required MyspaceThemePreset themePreset,
  }) {
    return ListenableBuilder(
      listenable: appState.audioEngine,
      builder: (context, _) {
        final isPlaying = appState.audioEngine.isTrackPlaying(track.id);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F14).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isPinned
                  ? themePreset.accentColor.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => appState.audioEngine.togglePlay(
                  track,
                  onFirstPlay: () => appState.incrementPlayCount(track.id),
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (track.externalPlatform != null) ...[
                          const SizedBox(width: 6),
                          SocialPlatformBadge(
                            platform: track.externalPlatform!,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${track.genre}  •  ${track.playCount} dinlenme',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Instagram / TikTok\'a Aktar',
                visualDensity: VisualDensity.compact,
                onPressed: () => showSocialShareStudioSheet(
                  context: context,
                  track: track,
                  artist: artist,
                  appState: appState,
                ),
                icon: const Icon(
                  Icons.ios_share_rounded,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
              if (isOwnProfile)
                IconButton(
                  tooltip: isPinned ? 'İmza Parça' : 'İmza Parça Yap',
                  visualDensity: VisualDensity.compact,
                  onPressed: isPinned
                      ? null
                      : () => appState.updateMyspaceProfile(
                            pinnedTrackId: track.id,
                          ),
                  icon: Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: isPinned ? themePreset.accentColor : Colors.white24,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRoomSheet(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);
    bool openCollab = user.isOpenToCollab;
    final selectedStyles = Set<String>.from(user.musicStyles);
    final selectedRoles = Set<String>.from(user.roles);
    String selectedTheme = user.themeGradient;
    Uint8List? newAvatarBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0F14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profili & Odayı Düzenle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await appState.updateMyspaceProfile(
                              displayName: nameCtrl.text.trim(),
                              bio: bioCtrl.text.trim(),
                              themeGradient: selectedTheme,
                              isOpenToCollab: openCollab,
                              musicStyles: selectedStyles.toList(),
                              roles: selectedRoles.toList(),
                              avatarBytes: newAvatarBytes,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            final res = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (res != null && res.files.isNotEmpty) {
                              setSheetState(
                                  () => newAvatarBytes = res.files.first.bytes);
                            }
                          } catch (_) {}
                        },
                        child: Column(
                          children: [
                            if (newAvatarBytes != null)
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: MemoryImage(newAvatarBytes!),
                              )
                            else
                              UserAvatar(
                                user: user,
                                appState: appState,
                                radius: 30,
                              ),
                            const SizedBox(height: 6),
                            const Text(
                              'Fotoğrafı Değiştir',
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Sanatçı / Görünür Ad',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Biyografi',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'İş Birliğine Açık (Open to Collab)',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      value: openCollab,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) =>
                          setSheetState(() => openCollab = val),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Yaptığın Müzik Türleri',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppState.availableMusicStyles.map((style) {
                        final has = selectedStyles.contains(style);
                        return FilterChip(
                          label: Text(style),
                          selected: has,
                          selectedColor:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          checkmarkColor: const Color(0xFF8B5CF6),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: has ? Colors.white : Colors.white54,
                            fontSize: 11.5,
                          ),
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                selectedStyles.add(style);
                              } else {
                                selectedStyles.remove(style);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rol / Enstrüman',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppState.availableCollabRoles.map((role) {
                        final has = selectedRoles.contains(role);
                        return FilterChip(
                          label: Text(role),
                          selected: has,
                          selectedColor:
                              const Color(0xFF10B981).withValues(alpha: 0.25),
                          checkmarkColor: const Color(0xFF10B981),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: has ? Colors.white : Colors.white54,
                            fontSize: 11.5,
                          ),
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                selectedRoles.add(role);
                              } else {
                                selectedRoles.remove(role);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
