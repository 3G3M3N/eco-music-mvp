import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/audio_engine.dart';
import '../widgets/interactive_waveform.dart';
import '../widgets/report_dialog.dart';
import '../widgets/social_video_embed.dart';

class FeedScreen extends StatelessWidget {
  final AppState appState;
  final ValueChanged<AppUser> onOpenArtistProfile;
  final void Function(AppUser artist, {Track? referenceTrack}) onStartCollabChat;
  final VoidCallback? onGoToUpload;

  const FeedScreen({
    super.key,
    required this.appState,
    required this.onOpenArtistProfile,
    required this.onStartCollabChat,
    this.onGoToUpload,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = appState.feedTracks;

    return Column(
      children: [
        // Refined Studio Filter Bar
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF050507),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                itemCount: AppState.genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = AppState.genres[index];
                  final isSelected = appState.selectedGenre == genre;
                  return GestureDetector(
                    onTap: () => appState.setSelectedGenre(genre),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF101218),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF050507)
                              : Colors.white60,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        Expanded(
          child: tracks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1016),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                            child: const Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white54,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Akış henüz boş',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'İlk cover performansını, YouTube / TikTok videosunu veya orijinal demonu paylaşarak sahneyi başlat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                          if (onGoToUpload != null) ...[
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 40,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF050507),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: onGoToUpload,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Kayıt Paylaş',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _StudioFeedCard(
                            track: track,
                            appState: appState,
                            onOpenArtistProfile: onOpenArtistProfile,
                            onStartCollabChat: onStartCollabChat,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StudioFeedCard extends StatefulWidget {
  final Track track;
  final AppState appState;
  final ValueChanged<AppUser> onOpenArtistProfile;
  final void Function(AppUser artist, {Track? referenceTrack}) onStartCollabChat;

  const _StudioFeedCard({
    required this.track,
    required this.appState,
    required this.onOpenArtistProfile,
    required this.onStartCollabChat,
  });

  @override
  State<_StudioFeedCard> createState() => _StudioFeedCardState();
}

class _StudioFeedCardState extends State<_StudioFeedCard> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _isSocialVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
  }

  void _initVideoIfNeeded() {
    final track = widget.track;
    if (track.hasExternalLink) return;

    final localVideoBytes = widget.appState.getVideoBytes(track.id);
    if (localVideoBytes != null) {
      final dataUri =
          Uri.dataFromBytes(localVideoBytes, mimeType: 'video/mp4');
      _videoController = VideoPlayerController.networkUrl(dataUri)
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) setState(() => _videoReady = true);
        }).catchError((_) {});
      return;
    }

    final url = track.videoUrl;
    if (track.isVideo &&
        url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) setState(() => _videoReady = true);
        }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final track = widget.track;
    final appState = widget.appState;

    if (track.hasExternalLink) {
      setState(() {
        _isSocialVideoPlaying = !_isSocialVideoPlaying;
      });
      if (_isSocialVideoPlaying) {
        appState.incrementPlayCount(track.id);
        appState.audioEngine.pause();
      }
      return;
    }

    appState.audioEngine.togglePlay(
      track,
      onFirstPlay: () => appState.incrementPlayCount(track.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final appState = widget.appState;
    final artist = appState.getUserById(track.userId);
    if (artist == null) return const SizedBox.shrink();

    final me = appState.currentUser;
    final themePreset = MyspaceThemePreset.fromId(artist.themeGradient);
    final comments = appState.commentsForTrack(track.id);
    final isLiked = me != null && track.likedByUserIds.contains(me.id);
    final isSaved = me != null && track.savedByUserIds.contains(me.id);
    final isFollowing = appState.isFollowing(artist.id);
    final isEarlySupporter = me != null &&
        appState.isEarlySupporterOf(followerId: me.id, artistId: artist.id);
    final customCoverBytes = appState.getCoverBytes(track.id);
    final artistAvatarBytes = appState.getAvatarBytes(artist.id);
    final artistTags = artist.combinedTags;

    return ListenableBuilder(
      listenable: appState.audioEngine,
      builder: (context, _) {
        final audio = appState.audioEngine;
        final isActive = audio.isTrackActive(track.id);
        final isPlaying = track.hasExternalLink
            ? _isSocialVideoPlaying
            : audio.isTrackPlaying(track.id);
        final currentSec = isActive ? audio.currentSeconds : 0.0;

        if (_videoReady && _videoController != null) {
          if (isPlaying && !_videoController!.value.isPlaying) {
            _videoController!.play();
          } else if (!isPlaying && _videoController!.value.isPlaying) {
            _videoController!.pause();
          }
        }

        TrackComment? activeComment;
        if (comments.isNotEmpty) {
          for (final c in comments) {
            if ((c.timestampSec - currentSec).abs() <= 2.0) {
              activeComment = c;
              break;
            }
          }
          activeComment ??= comments.first;
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0C10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Editorial Artist Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onOpenArtistProfile(artist),
                      child: UserAvatar(
                        user: artist,
                        appState: appState,
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onOpenArtistProfile(artist),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    artist.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '@${artist.username}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                if (isEarlySupporter) ...[
                                  const SizedBox(width: 6),
                                  const EarlySupporterBadge(compact: true),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (artist.isOpenToCollab) ...[
                                  const OpenToCollabBadge(compact: true),
                                  const SizedBox(width: 6),
                                ],
                                if (artistTags.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      artistTags.take(3).join(' · '),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (me != null && me.id != artist.id)
                      GestureDetector(
                        onTap: () => appState.toggleFollow(artist.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isFollowing
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  )
                                : null,
                          ),
                          child: Text(
                            isFollowing ? 'Takipte' : 'Takip Et',
                            style: TextStyle(
                              color: isFollowing
                                  ? Colors.white70
                                  : const Color(0xFF050507),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      color: const Color(0xFF14161E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'share') {
                          await showSocialShareStudioSheet(
                            context: context,
                            track: track,
                            artist: artist,
                            appState: appState,
                          );
                        } else if (value == 'report_track') {
                          await showReportContentDialog(
                            context: context,
                            appState: appState,
                            targetType: 'track',
                            targetId: track.id,
                            targetSummary:
                                '${track.title} (@${artist.username})',
                            targetOwnerId: artist.id,
                          );
                        } else if (value == 'block_user') {
                          await appState.blockUser(artist.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Text(
                            'Paylaş / Aktar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report_track',
                          child: Text(
                            'İçeriği Bildir',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        if (me != null && me.id != artist.id)
                          const PopupMenuItem(
                            value: 'block_user',
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
              ),

              // 2. Clean 16:9 Cinema Stage (Pure video embed when playing, clean artwork when paused)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: (track.hasExternalLink && _isSocialVideoPlaying)
                        ? SocialVideoEmbedPlayer(
                            trackId: track.id,
                            externalUrl: track.externalUrl!,
                            platform: track.externalPlatform,
                          )
                        : GestureDetector(
                            onTap: _togglePlayPause,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (track.isVideo &&
                                    _videoReady &&
                                    _videoController != null)
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width:
                                          _videoController!.value.size.width,
                                      height:
                                          _videoController!.value.size.height,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  )
                                else if (customCoverBytes != null)
                                  Image.memory(
                                    customCoverBytes,
                                    fit: BoxFit.cover,
                                  )
                                else if (track.coverUrl.isNotEmpty &&
                                    track.coverUrl.startsWith('http'))
                                  Image.network(
                                    track.coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildFallbackStage(
                                      artist,
                                      appState,
                                      themePreset,
                                    ),
                                  )
                                else if (artistAvatarBytes != null)
                                  Image.memory(
                                    artistAvatarBytes,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  _buildFallbackStage(
                                    artist,
                                    appState,
                                    themePreset,
                                  ),

                                // Subtle vignette
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.25),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.45),
                                      ],
                                    ),
                                  ),
                                ),

                                // Top-Left Genre & Platform Pills
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: Text(
                                          track.genre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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
                                ),

                                // Center Frosted Play Trigger when idle
                                if (!isPlaying)
                                  Center(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.65),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),

              // 3. Dedicated Studio Control & Track Metadata Deck (Always visible below video/stage!)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single Unified Play / Pause (Stop) Symbol Button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? Colors.white
                              : themePreset.accentColor,
                          shape: BoxShape.circle,
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
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${track.playCount} dinlenme',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (track.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              track.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (track.tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: track.tags.map((t) {
                                return Text(
                                  t,
                                  style: TextStyle(
                                    color: themePreset.accentColor
                                        .withValues(alpha: 0.9),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Interactive Waveform (for audio files)
              if (!track.hasExternalLink)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: InteractiveWaveform(
                    track: track,
                    comments: comments,
                    isPlaying: isPlaying,
                    currentSeconds: currentSec,
                    accentColor: themePreset.accentColor,
                    onSeekToSecond: (sec) {
                      audio.seekToSecond(
                        track,
                        sec,
                        onFirstPlay: () =>
                            appState.incrementPlayCount(track.id),
                      );
                    },
                    onCommentMarkerTap: (comment) {
                      _showCommentsSheet(
                        context,
                        initialSecond: comment.timestampSec,
                      );
                    },
                  ),
                ),

              // 5. Timestamped Comment Preview Pill
              if (activeComment != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: GestureDetector(
                    onTap: () => _showCommentsSheet(
                      context,
                      initialSecond: activeComment!.timestampSec,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11131A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final cAuthor =
                              appState.getUserById(activeComment!.userId);
                          final isEarly = appState.isEarlySupporterOf(
                            followerId: activeComment.userId,
                            artistId: artist.id,
                          );
                          return Row(
                            children: [
                              Text(
                                AudioEngine.formatDuration(
                                    activeComment.timestampSec),
                                style: TextStyle(
                                  color: themePreset.accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '@${cAuthor?.username ?? "user"}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                              if (isEarly) ...[
                                const SizedBox(width: 6),
                                const EarlySupporterBadge(compact: true),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeComment.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // 6. Clean Studio Interaction Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 14, 12),
                child: Row(
                  children: [
                    _buildActionPill(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked
                          ? const Color(0xFFF43F5E)
                          : Colors.white60,
                      label: '${track.likedByUserIds.length}',
                      onTap: () => appState.toggleLike(track.id),
                    ),
                    const SizedBox(width: 6),
                    _buildActionPill(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.white60,
                      label: '${comments.length}',
                      onTap: () => _showCommentsSheet(
                        context,
                        initialSecond: currentSec.floor(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildActionPill(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isSaved
                          ? themePreset.accentColor
                          : Colors.white60,
                      onTap: () => appState.toggleSave(track.id),
                    ),
                    const SizedBox(width: 6),
                    _buildActionPill(
                      icon: Icons.ios_share_rounded,
                      color: Colors.white60,
                      onTap: () => showSocialShareStudioSheet(
                        context: context,
                        track: track,
                        artist: artist,
                        appState: appState,
                      ),
                    ),
                    const Spacer(),
                    if (me == null || me.id != artist.id)
                      GestureDetector(
                        onTap: () => widget.onStartCollabChat(
                          artist,
                          referenceTrack: track,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.handshake_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'İş Birliği',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackStage(
    AppUser artist,
    AppState appState,
    MyspaceThemePreset themePreset,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themePreset.gradientColors,
        ),
      ),
      child: Center(
        child: UserAvatar(
          user: artist,
          appState: appState,
          radius: 42,
        ),
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context, {
    required int initialSecond,
  }) {
    final track = widget.track;
    final appState = widget.appState;
    int selectedSecond = initialSecond.clamp(0, track.durationSec);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0C10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final comments = appState.commentsForTrack(track.id);
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yorumlar (${comments.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AudioEngine.formatDuration(selectedSecond),
                            style: const TextStyle(
                              color: Color(0xFF050507),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: selectedSecond.toDouble(),
                            min: 0,
                            max: track.durationSec.toDouble(),
                            activeColor: Colors.white,
                            onChanged: (val) {
                              setSheetState(() => selectedSecond = val.round());
                              if (!track.hasExternalLink) {
                                appState.audioEngine.seekToSecond(track, val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Henüz yorum yok.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: comments.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Colors.white10,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final c = comments[index];
                                final author = appState.getUserById(c.userId);
                                final isEarly = appState.isEarlySupporterOf(
                                  followerId: c.userId,
                                  artistId: track.userId,
                                );
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    if (!track.hasExternalLink) {
                                      appState.audioEngine.seekToSecond(
                                        track,
                                        c.timestampSec.toDouble(),
                                      );
                                    }
                                    setSheetState(
                                        () => selectedSecond = c.timestampSec);
                                  },
                                  leading: Text(
                                    AudioEngine.formatDuration(c.timestampSec),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        '@${author?.username ?? "user"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isEarly) ...[
                                        const SizedBox(width: 6),
                                        const EarlySupporterBadge(compact: true),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    c.content,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_horiz_rounded,
                                      color: Colors.white30,
                                      size: 16,
                                    ),
                                    color: const Color(0xFF14161E),
                                    onSelected: (val) async {
                                      if (val == 'report') {
                                        await showReportContentDialog(
                                          context: context,
                                          appState: appState,
                                          targetType: 'comment',
                                          targetId: c.id,
                                          targetSummary: c.content,
                                          targetOwnerId: c.userId,
                                        );
                                      } else if (val == 'block') {
                                        await appState.blockUser(c.userId);
                                        setSheetState(() {});
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'report',
                                        child: Text(
                                          'Bildir',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'block',
                                        child: Text(
                                          'Engelle',
                                          style: TextStyle(
                                            color: Color(0xFFF43F5E),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  '${AudioEngine.formatDuration(selectedSecond)} için yorum yaz...',
                              hintStyle: const TextStyle(
                                color: Colors.white30,
                                fontSize: 12.5,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF050507),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (commentController.text.trim().isEmpty) return;
                            await appState.addTimestampedComment(
                              trackId: track.id,
                              content: commentController.text,
                              timestampSec: selectedSecond,
                            );
                            commentController.clear();
                            setSheetState(() {});
                          },
                          child: const Text(
                            'Gönder',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
