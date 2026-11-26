import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String bio;
  final String themeGradient;
  final bool isOpenToCollab;
  final List<String> musicStyles; // Yapılan müzik türleri: Rap, Indie, Alternatif Rock vb.
  final List<String> roles; // Vokal, Prodüktör, Gitarist vb.
  final String? pinnedTrackId;
  final int followerCount;
  final String role; // 'user' | 'admin'
  final bool isSuspended;
  final DateTime? termsAcceptedAt;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.themeGradient,
    required this.isOpenToCollab,
    this.musicStyles = const [],
    required this.roles,
    this.pinnedTrackId,
    required this.followerCount,
    required this.role,
    this.isSuspended = false,
    this.termsAcceptedAt,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  /// Kullanıcının yaptığı müzik türleri ve rollerinin birleşik özeti
  List<String> get combinedTags {
    final result = <String>[...musicStyles, ...roles];
    return result.toSet().toList();
  }

  AppUser copyWith({
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    String? themeGradient,
    bool? isOpenToCollab,
    List<String>? musicStyles,
    List<String>? roles,
    String? pinnedTrackId,
    bool clearPinnedTrack = false,
    int? followerCount,
    String? role,
    bool? isSuspended,
    DateTime? termsAcceptedAt,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      themeGradient: themeGradient ?? this.themeGradient,
      isOpenToCollab: isOpenToCollab ?? this.isOpenToCollab,
      musicStyles: musicStyles ?? this.musicStyles,
      roles: roles ?? this.roles,
      pinnedTrackId:
          clearPinnedTrack ? null : (pinnedTrackId ?? this.pinnedTrackId),
      followerCount: followerCount ?? this.followerCount,
      role: role ?? this.role,
      isSuspended: isSuspended ?? this.isSuspended,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'theme_gradient': themeGradient,
      'is_open_to_collab': isOpenToCollab,
      'music_styles': musicStyles,
      'roles': roles,
      'pinned_track_id': pinnedTrackId,
      'follower_count': followerCount,
      'role': role,
      'is_suspended': isSuspended,
      'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String? ?? 'user',
      displayName:
          map['display_name'] as String? ?? map['username'] as String? ?? 'Sanatçı',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      themeGradient: map['theme_gradient'] as String? ?? 'obsidian_violet',
      isOpenToCollab: map['is_open_to_collab'] as bool? ?? true,
      musicStyles: List<String>.from(map['music_styles'] as List? ?? const []),
      roles: List<String>.from(map['roles'] as List? ?? const []),
      pinnedTrackId: map['pinned_track_id'] as String?,
      followerCount: (map['follower_count'] as num?)?.toInt() ?? 0,
      role: map['role'] as String? ?? 'user',
      isSuspended: map['is_suspended'] as bool? ?? false,
      termsAcceptedAt: map['terms_accepted_at'] != null
          ? DateTime.tryParse(map['terms_accepted_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class Track {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String mediaType; // 'audio' | 'video' | 'social_link'
  final String audioUrl;
  final String? videoUrl;
  final String? externalUrl; // TikTok, Instagram Reels, YouTube linki
  final String? externalPlatform; // 'tiktok' | 'instagram' | 'youtube'
  final String coverUrl;
  final String genre;
  final List<String> tags;
  final int durationSec;
  final int playCount;
  final List<String> likedByUserIds;
  final List<String> savedByUserIds;
  final List<double> waveform;
  final DateTime copyrightAcceptedAt;
  final String copyrightAcceptedByUserId;
  final bool isHidden;
  final DateTime createdAt;

  const Track({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.mediaType = 'audio',
    required this.audioUrl,
    this.videoUrl,
    this.externalUrl,
    this.externalPlatform,
    required this.coverUrl,
    required this.genre,
    required this.tags,
    required this.durationSec,
    required this.playCount,
    this.likedByUserIds = const [],
    this.savedByUserIds = const [],
    required this.waveform,
    required this.copyrightAcceptedAt,
    required this.copyrightAcceptedByUserId,
    this.isHidden = false,
    required this.createdAt,
  });

  bool get isVideo => mediaType == 'video' || mediaType == 'social_link';
  bool get hasExternalLink =>
      externalUrl != null && externalUrl!.trim().isNotEmpty;

  /// Sosyal medya linkinden platformu otomatik algılar ('tiktok' | 'instagram' | 'youtube' | 'external')
  static String? detectSocialPlatform(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final lower = rawUrl.trim().toLowerCase();
    if (lower.contains('tiktok.com')) return 'tiktok';
    if (lower.contains('instagram.com') || lower.contains('instagr.am')) {
      return 'instagram';
    }
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'youtube';
    }
    return 'external';
  }

  /// YouTube linkiyse video ID'sini çıkarıp otomatik kapak görselini (thumbnail) döndürür
  static String? extractYoutubeThumbnail(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return null;

    String? videoId;
    if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        videoId = uri.pathSegments.first;
      }
    } else if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments[0] == 'shorts' || uri.pathSegments[0] == 'embed')) {
        videoId = uri.pathSegments[1];
      }
    }
    if (videoId != null && videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  Track copyWith({
    String? title,
    String? description,
    String? mediaType,
    String? audioUrl,
    String? videoUrl,
    String? externalUrl,
    String? externalPlatform,
    String? coverUrl,
    String? genre,
    List<String>? tags,
    int? durationSec,
    int? playCount,
    List<String>? likedByUserIds,
    List<String>? savedByUserIds,
    List<double>? waveform,
    bool? isHidden,
  }) {
    return Track(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaType: mediaType ?? this.mediaType,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      externalPlatform: externalPlatform ?? this.externalPlatform,
      coverUrl: coverUrl ?? this.coverUrl,
      genre: genre ?? this.genre,
      tags: tags ?? this.tags,
      durationSec: durationSec ?? this.durationSec,
      playCount: playCount ?? this.playCount,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      savedByUserIds: savedByUserIds ?? this.savedByUserIds,
      waveform: waveform ?? this.waveform,
      copyrightAcceptedAt: copyrightAcceptedAt,
      copyrightAcceptedByUserId: copyrightAcceptedByUserId,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'media_type': mediaType,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'external_url': externalUrl,
      'external_platform': externalPlatform,
      'cover_url': coverUrl,
      'genre': genre,
      'tags': tags,
      'duration': durationSec,
      'play_count': playCount,
      'liked_by_user_ids': likedByUserIds,
      'saved_by_user_ids': savedByUserIds,
      'waveform': waveform,
      'copyright_accepted_at': copyrightAcceptedAt.toIso8601String(),
      'copyright_accepted_by_user_id': copyrightAcceptedByUserId,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      description: map['description'] as String? ?? '',
      mediaType: map['media_type'] as String? ?? 'audio',
      audioUrl: map['audio_url'] as String? ?? '',
      videoUrl: map['video_url'] as String?,
      externalUrl: map['external_url'] as String?,
      externalPlatform: map['external_platform'] as String?,
      coverUrl: map['cover_url'] as String? ?? '',
      genre: map['genre'] as String? ?? 'Indie',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      durationSec: (map['duration'] as num?)?.toInt() ?? 45,
      playCount: (map['play_count'] as num?)?.toInt() ?? 0,
      likedByUserIds:
          List<String>.from(map['liked_by_user_ids'] as List? ?? const []),
      savedByUserIds:
          List<String>.from(map['saved_by_user_ids'] as List? ?? const []),
      waveform: (map['waveform'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [0.3, 0.5, 0.8, 0.6, 0.9, 0.4, 0.7],
      copyrightAcceptedAt:
          DateTime.tryParse(map['copyright_accepted_at'] as String? ?? '') ??
              DateTime.now(),
      copyrightAcceptedByUserId:
          map['copyright_accepted_by_user_id'] as String? ??
              map['user_id'] as String? ??
              '',
      isHidden: map['is_hidden'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TrackComment {
  final String id;
  final String trackId;
  final String userId;
  final String content;
  final int timestampSec;
  final bool isHidden;
  final DateTime createdAt;

  const TrackComment({
    required this.id,
    required this.trackId,
    required this.userId,
    required this.content,
    required this.timestampSec,
    this.isHidden = false,
    required this.createdAt,
  });

  TrackComment copyWith({bool? isHidden}) {
    return TrackComment(
      id: id,
      trackId: trackId,
      userId: userId,
      content: content,
      timestampSec: timestampSec,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track_id': trackId,
      'user_id': userId,
      'content': content,
      'timestamp_sec': timestampSec,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrackComment.fromMap(Map<String, dynamic> map) {
    return TrackComment(
      id: map['id'] as String,
      trackId: map['track_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      timestampSec: (map['timestamp_sec'] as num?)?.toInt() ?? 0,
      isHidden: map['is_hidden'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class FollowRelation {
  final String followerId;
  final String followingId;
  final bool isEarlySupporter;
  final DateTime createdAt;

  const FollowRelation({
    required this.followerId,
    required this.followingId,
    required this.isEarlySupporter,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'follower_id': followerId,
      'following_id': followingId,
      'is_early_supporter': isEarlySupporter,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FollowRelation.fromMap(Map<String, dynamic> map) {
    return FollowRelation(
      followerId: map['follower_id'] as String,
      followingId: map['following_id'] as String,
      isEarlySupporter: map['is_early_supporter'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DirectMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isCollabRequest;
  final String? collabRole;
  final String? referenceTrackId;
  final DateTime createdAt;

  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isCollabRequest,
    this.collabRole,
    this.referenceTrackId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_collab_request': isCollabRequest,
      'collab_role': collabRole,
      'reference_track_id': referenceTrackId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DirectMessage.fromMap(Map<String, dynamic> map) {
    return DirectMessage(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      content: map['content'] as String? ?? '',
      isCollabRequest: map['is_collab_request'] as bool? ?? false,
      collabRole: map['collab_role'] as String?,
      referenceTrackId: map['reference_track_id'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ContentReport {
  final String id;
  final String reporterId;
  final String targetType; // 'track' | 'comment' | 'user'
  final String targetId;
  final String targetSummary;
  final String targetOwnerId;
  final String reason;
  final String details;
  final String status; // 'pending' | 'resolved'
  final DateTime createdAt;

  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetSummary,
    required this.targetOwnerId,
    required this.reason,
    this.details = '',
    required this.status,
    required this.createdAt,
  });

  ContentReport copyWith({String? status}) {
    return ContentReport(
      id: id,
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      targetSummary: targetSummary,
      targetOwnerId: targetOwnerId,
      reason: reason,
      details: details,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_id': targetId,
      'target_summary': targetSummary,
      'target_owner_id': targetOwnerId,
      'reason': reason,
      'details': details,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ContentReport.fromMap(Map<String, dynamic> map) {
    return ContentReport(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String,
      targetType: map['target_type'] as String? ?? 'track',
      targetId: map['target_id'] as String,
      targetSummary: map['target_summary'] as String? ?? '',
      targetOwnerId: map['target_owner_id'] as String? ?? '',
      reason: map['reason'] as String? ?? 'Telif Hakkı İhlali (DMCA/5651)',
      details: map['details'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class UserBlock {
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;

  const UserBlock({
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserBlock.fromMap(Map<String, dynamic> map) {
    return UserBlock(
      blockerId: map['blocker_id'] as String,
      blockedId: map['blocked_id'] as String,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class MyspaceThemePreset {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color accentColor;

  const MyspaceThemePreset({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.accentColor,
  });

  static const List<MyspaceThemePreset> presets = [
    MyspaceThemePreset(
      id: 'obsidian_violet',
      name: 'Obsidian',
      gradientColors: [Color(0xFF140C24), Color(0xFF0A0A0E), Color(0xFF070709)],
      accentColor: Color(0xFF8B5CF6),
    ),
    MyspaceThemePreset(
      id: 'emerald_pulse',
      name: 'Pulse',
      gradientColors: [Color(0xFF071F18), Color(0xFF090D0C), Color(0xFF070709)],
      accentColor: Color(0xFF10B981),
    ),
    MyspaceThemePreset(
      id: 'crimson_room',
      name: 'Velvet',
      gradientColors: [Color(0xFF220911), Color(0xFF0E080B), Color(0xFF070709)],
      accentColor: Color(0xFFF43F5E),
    ),
    MyspaceThemePreset(
      id: 'cobalt_night',
      name: 'Cobalt',
      gradientColors: [Color(0xFF08162B), Color(0xFF090C12), Color(0xFF070709)],
      accentColor: Color(0xFF38BDF8),
    ),
    MyspaceThemePreset(
      id: 'amber_tape',
      name: 'Warm Tape',
      gradientColors: [Color(0xFF231307), Color(0xFF0F0B08), Color(0xFF070709)],
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  static MyspaceThemePreset fromId(String id) {
    return presets.firstWhere(
      (p) => p.id == id,
      orElse: () => presets.first,
    );
  }
}
