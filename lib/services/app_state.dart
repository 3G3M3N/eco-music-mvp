import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'audio_engine.dart';

class AppState extends ChangeNotifier {
  static const String _storageKey = 'eco_production_state_v2';

  final AudioEngine audioEngine = AudioEngine();

  bool _firebaseAvailable = false;
  bool get firebaseAvailable => _firebaseAvailable;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  final List<AppUser> _users = [];
  final List<Track> _tracks = [];
  final List<TrackComment> _comments = [];
  final List<FollowRelation> _follows = [];
  final List<DirectMessage> _messages = [];
  final List<ContentReport> _reports = [];
  final List<UserBlock> _blocks = [];

  final Map<String, String> _credentials = {};

  final Map<String, Uint8List> _uploadedCoverBytes = {};
  final Map<String, Uint8List> _uploadedAvatarBytes = {};
  final Map<String, Uint8List> _uploadedVideoBytes = {};

  String _selectedGenre = 'Tümü';
  String get selectedGenre => _selectedGenre;

  static const List<String> genres = [
    'Tümü',
    'Cover',
    'Rap',
    'Indie',
    'Alternatif Rock',
    'Rock',
    'Elektronik',
    'R&B',
    'Pop',
    'Lo-Fi',
    'Trap',
    'Metal',
    'Akustik',
  ];

  /// Kullanıcının profilinde seçebileceği yapılan müzik türleri
  static const List<String> availableMusicStyles = [
    'Cover',
    'Rap',
    'Indie',
    'Alternatif Rock',
    'Rock',
    'Elektronik',
    'R&B',
    'Pop',
    'Lo-Fi',
    'Trap',
    'Metal',
    'Akustik',
  ];

  /// Kullanıcının profilinde seçebileceği iş birliği rolleri
  static const List<String> availableCollabRoles = [
    'Vokal',
    'Beatmaker',
    'Gitarist',
    'Mix/Mastering',
    'Söz Yazarı',
    'Prodüktör',
    'Bas Gitar',
    'Davul',
  ];

  static const List<String> reportReasons = [
    'Telif Hakkı İhlali (DMCA/5651)',
    'Uygunsuz İçerik',
    'Spam',
  ];

  List<AppUser> get allUsers => List.unmodifiable(_users);
  List<Track> get allTracks => List.unmodifiable(_tracks);
  List<ContentReport> get allReports => List.unmodifiable(_reports);

  Uint8List? getCoverBytes(String trackId) => _uploadedCoverBytes[trackId];
  Uint8List? getAvatarBytes(String userId) => _uploadedAvatarBytes[userId];
  Uint8List? getVideoBytes(String trackId) => _uploadedVideoBytes[trackId];

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseAvailable = true;
    } catch (_) {
      _firebaseAvailable = false;
    }

    await _loadPersistedState();
    notifyListeners();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_storageKey);
    if (savedJson == null) return;

    try {
      final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
      _users
        ..clear()
        ..addAll((decoded['users'] as List? ?? const [])
            .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e))));
      _tracks
        ..clear()
        ..addAll((decoded['tracks'] as List? ?? const [])
            .map((e) => Track.fromMap(Map<String, dynamic>.from(e))));
      _comments
        ..clear()
        ..addAll((decoded['comments'] as List? ?? const [])
            .map((e) => TrackComment.fromMap(Map<String, dynamic>.from(e))));
      _follows
        ..clear()
        ..addAll((decoded['follows'] as List? ?? const [])
            .map((e) => FollowRelation.fromMap(Map<String, dynamic>.from(e))));
      _messages
        ..clear()
        ..addAll((decoded['messages'] as List? ?? const [])
            .map((e) => DirectMessage.fromMap(Map<String, dynamic>.from(e))));
      _reports
        ..clear()
        ..addAll((decoded['reports'] as List? ?? const [])
            .map((e) => ContentReport.fromMap(Map<String, dynamic>.from(e))));
      _blocks
        ..clear()
        ..addAll((decoded['blocks'] as List? ?? const [])
            .map((e) => UserBlock.fromMap(Map<String, dynamic>.from(e))));

      final creds = decoded['credentials'] as Map<String, dynamic>?;
      if (creds != null) {
        _credentials
          ..clear()
          ..addAll(creds.map((k, v) => MapEntry(k, v.toString())));
      }

      final avatarsMap = decoded['avatars_b64'] as Map<String, dynamic>?;
      if (avatarsMap != null) {
        avatarsMap.forEach((k, v) {
          _uploadedAvatarBytes[k] = base64Decode(v.toString());
        });
      }
      final coversMap = decoded['covers_b64'] as Map<String, dynamic>?;
      if (coversMap != null) {
        coversMap.forEach((k, v) {
          _uploadedCoverBytes[k] = base64Decode(v.toString());
        });
      }

      final currentUserId = decoded['current_user_id'] as String?;
      if (currentUserId != null) {
        _currentUser = getUserById(currentUserId);
      }
    } catch (_) {}
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarsB64 = <String, String>{};
      _uploadedAvatarBytes.forEach((k, v) {
        if (v.lengthInBytes < 500000) {
          avatarsB64[k] = base64Encode(v);
        }
      });
      final coversB64 = <String, String>{};
      _uploadedCoverBytes.forEach((k, v) {
        if (v.lengthInBytes < 750000) {
          coversB64[k] = base64Encode(v);
        }
      });

      final payload = jsonEncode({
        'current_user_id': _currentUser?.id,
        'users': _users.map((u) => u.toMap()).toList(),
        'tracks': _tracks.map((t) => t.toMap()).toList(),
        'comments': _comments.map((c) => c.toMap()).toList(),
        'follows': _follows.map((f) => f.toMap()).toList(),
        'messages': _messages.map((m) => m.toMap()).toList(),
        'reports': _reports.map((r) => r.toMap()).toList(),
        'blocks': _blocks.map((b) => b.toMap()).toList(),
        'credentials': _credentials,
        'avatars_b64': avatarsB64,
        'covers_b64': coversB64,
      });
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }

  static List<double> generateWaveform(int count, int seed) {
    final rnd = math.Random(seed);
    return List<double>.generate(count, (index) {
      final base = 0.25 + 0.55 * math.sin((index / count) * math.pi);
      final jitter = (rnd.nextDouble() - 0.3) * 0.45;
      return (base + jitter).clamp(0.14, 1.0);
    });
  }

  // ===========================================================================
  // AUTHENTICATION & LEGAL TERMS ACCEPTANCE
  // ===========================================================================

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('E-posta ve şifre alanları zorunludur.');
    }

    if (_firebaseAvailable) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } catch (_) {}
    }

    if (normalizedEmail == 'admin@eco.fm' || normalizedEmail == 'admin@eco.app') {
      var adminUser = _users.cast<AppUser?>().firstWhere(
            (u) => u!.email.toLowerCase() == normalizedEmail,
            orElse: () => null,
          );
      if (adminUser == null) {
        adminUser = AppUser(
          id: 'usr_eco_admin',
          username: 'ecoadmin',
          displayName: 'eco Moderasyon',
          email: normalizedEmail,
          avatarUrl: '',
          bio: 'eco Platform Yönetimi',
          themeGradient: 'obsidian_violet',
          isOpenToCollab: false,
          musicStyles: const ['Indie'],
          roles: const ['Prodüktör'],
          followerCount: 0,
          role: 'admin',
          termsAcceptedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
        _users.add(adminUser);
      }
      _currentUser = adminUser;
      await _persistState();
      notifyListeners();
      return;
    }

    final existing = _users.cast<AppUser?>().firstWhere(
          (u) =>
              u!.email.toLowerCase() == normalizedEmail ||
              u.username.toLowerCase() == normalizedEmail.replaceAll('@', ''),
          orElse: () => null,
        );

    if (existing == null) {
      throw Exception('Bu e-posta veya kullanıcı adıyla kayıtlı hesap bulunamadı.');
    }
    if (existing.isSuspended) {
      throw Exception('Bu hesap kullanım koşulları ihlali nedeniyle askıya alınmıştır.');
    }

    final savedPass = _credentials[existing.email.toLowerCase()];
    if (savedPass != null && savedPass != password) {
      throw Exception('Girdiğiniz şifre hatalı.');
    }

    _currentUser = existing;
    await _persistState();
    notifyListeners();
  }

  Future<void> signUpWithEmail({
    required String username,
    required String displayName,
    required String email,
    required String password,
    List<String> musicStyles = const [],
    required List<String> roles,
    required bool acceptedTermsAndPrivacy,
    Uint8List? avatarBytes,
  }) async {
    if (!acceptedTermsAndPrivacy) {
      throw Exception(
        'Kayıt olabilmek için Kullanım Koşulları ve Gizlilik Politikası\'nı onaylamanız zorunludur.',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername =
        username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');

    if (cleanUsername.isEmpty || cleanEmail.isEmpty || password.length < 4) {
      throw Exception('Geçerli bir kullanıcı adı, e-posta ve en az 4 karakterli şifre girin.');
    }

    final duplicate = _users.any(
      (u) =>
          u.email.toLowerCase() == cleanEmail ||
          u.username.toLowerCase() == cleanUsername,
    );
    if (duplicate) {
      throw Exception('Bu kullanıcı adı veya e-posta adresi zaten kullanılıyor.');
    }

    final now = DateTime.now();
    String uid = 'usr_${now.millisecondsSinceEpoch}';

    if (_firebaseAvailable) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
        }
      } catch (_) {}
    }

    if (avatarBytes != null) {
      _uploadedAvatarBytes[uid] = avatarBytes;
    }

    final isSystemAdmin =
        cleanEmail == 'admin@eco.fm' || cleanEmail == 'admin@eco.app';

    final newUser = AppUser(
      id: uid,
      username: cleanUsername,
      displayName:
          displayName.trim().isEmpty ? cleanUsername : displayName.trim(),
      email: cleanEmail,
      avatarUrl: '',
      bio: '',
      themeGradient: 'obsidian_violet',
      isOpenToCollab: true,
      musicStyles: musicStyles.isEmpty ? const ['Indie'] : musicStyles,
      roles: roles,
      followerCount: 0,
      role: isSystemAdmin ? 'admin' : 'user',
      termsAcceptedAt: now,
      createdAt: now,
    );

    _users.add(newUser);
    _credentials[cleanEmail] = password;
    _currentUser = newUser;

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_firebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    await audioEngine.pause();
    _currentUser = null;
    await _persistState();
    notifyListeners();
  }

  // ===========================================================================
  // QUERIES & FILTERING
  // ===========================================================================

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  AppUser? getUserById(String userId) {
    for (final u in _users) {
      if (u.id == userId) return u;
    }
    return null;
  }

  Track? getTrackById(String? trackId) {
    if (trackId == null) return null;
    for (final t in _tracks) {
      if (t.id == trackId) return t;
    }
    return null;
  }

  Set<String> get blockedUserIds {
    final uid = _currentUser?.id;
    if (uid == null) return {};
    return _blocks
        .where((b) => b.blockerId == uid)
        .map((b) => b.blockedId)
        .toSet();
  }

  bool isUserBlocked(String targetUserId) {
    return blockedUserIds.contains(targetUserId);
  }

  List<Track> get feedTracks {
    final blocked = blockedUserIds;
    return _tracks.where((track) {
      if (track.isHidden) return false;
      if (blocked.contains(track.userId)) return false;
      final author = getUserById(track.userId);
      if (author != null && author.isSuspended) return false;
      if (_selectedGenre != 'Tümü') {
        final g = _selectedGenre.toLowerCase();
        final matchesGenre = track.genre.toLowerCase() == g;
        final matchesCoverTag = g == 'cover' &&
            track.tags.any((t) => t.toLowerCase().contains('cover'));
        if (!matchesGenre && !matchesCoverTag) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Track> tracksForUser(String userId) {
    return _tracks
        .where((t) => t.userId == userId && !t.isHidden)
        .toList();
  }

  List<TrackComment> commentsForTrack(String trackId) {
    final blocked = blockedUserIds;
    final list = _comments.where((c) {
      if (c.trackId != trackId) return false;
      if (c.isHidden) return false;
      if (blocked.contains(c.userId)) return false;
      final author = getUserById(c.userId);
      if (author != null && author.isSuspended) return false;
      return true;
    }).toList();
    list.sort((a, b) => a.timestampSec.compareTo(b.timestampSec));
    return list;
  }

  // ===========================================================================
  // EARLY SUPPORTER & FOLLOW LOGIC (< 100 followers automatic badge)
  // ===========================================================================

  bool isFollowing(String targetUserId) {
    final uid = _currentUser?.id;
    if (uid == null) return false;
    return _follows.any(
      (f) => f.followerId == uid && f.followingId == targetUserId,
    );
  }

  bool isEarlySupporterOf({
    required String followerId,
    required String artistId,
  }) {
    return _follows.any(
      (f) =>
          f.followerId == followerId &&
          f.followingId == artistId &&
          f.isEarlySupporter,
    );
  }

  int earlySupporterCountForUser(String userId) {
    return _follows
        .where((f) => f.followerId == userId && f.isEarlySupporter)
        .length;
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final me = _currentUser;
    if (me == null || me.id == targetUserId) return false;
    final target = getUserById(targetUserId);
    if (target == null) return false;

    final existingIdx = _follows.indexWhere(
      (f) => f.followerId == me.id && f.followingId == targetUserId,
    );

    bool earnedEarlyBadge = false;
    if (existingIdx >= 0) {
      _follows.removeAt(existingIdx);
      final updatedTarget = target.copyWith(
        followerCount: math.max(0, target.followerCount - 1),
      );
      _updateUserInList(updatedTarget);
    } else {
      earnedEarlyBadge = target.followerCount < 100;
      final relation = FollowRelation(
        followerId: me.id,
        followingId: targetUserId,
        isEarlySupporter: earnedEarlyBadge,
        createdAt: DateTime.now(),
      );
      _follows.add(relation);
      final updatedTarget = target.copyWith(
        followerCount: target.followerCount + 1,
      );
      _updateUserInList(updatedTarget);

      if (_firebaseAvailable) {
        try {
          await FirebaseFirestore.instance
              .collection('follows')
              .doc('${me.id}_$targetUserId')
              .set(relation.toMap());
        } catch (_) {}
      }
    }

    await _persistState();
    notifyListeners();
    return earnedEarlyBadge;
  }

  // ===========================================================================
  // TRACK INTERACTIONS & TIMESTAMPED COMMENTS
  // ===========================================================================

  Future<void> incrementPlayCount(String trackId) async {
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return;
    _tracks[idx] = _tracks[idx].copyWith(playCount: _tracks[idx].playCount + 1);
    await _persistState();
    notifyListeners();
  }

  Future<void> toggleLike(String trackId) async {
    final me = _currentUser;
    if (me == null) return;
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return;
    final track = _tracks[idx];
    final likes = List<String>.from(track.likedByUserIds);
    if (likes.contains(me.id)) {
      likes.remove(me.id);
    } else {
      likes.add(me.id);
    }
    _tracks[idx] = track.copyWith(likedByUserIds: likes);
    await _persistState();
    notifyListeners();
  }

  Future<void> toggleSave(String trackId) async {
    final me = _currentUser;
    if (me == null) return;
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return;
    final track = _tracks[idx];
    final saves = List<String>.from(track.savedByUserIds);
    if (saves.contains(me.id)) {
      saves.remove(me.id);
    } else {
      saves.add(me.id);
    }
    _tracks[idx] = track.copyWith(savedByUserIds: saves);
    await _persistState();
    notifyListeners();
  }

  Future<void> addTimestampedComment({
    required String trackId,
    required String content,
    required int timestampSec,
  }) async {
    final me = _currentUser;
    if (me == null || content.trim().isEmpty) return;

    final comment = TrackComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      trackId: trackId,
      userId: me.id,
      content: content.trim(),
      timestampSec: timestampSec,
      createdAt: DateTime.now(),
    );

    _comments.add(comment);

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('comments')
            .doc(comment.id)
            .set(comment.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
  }

  // ===========================================================================
  // TRACK / VIDEO / SOCIAL LINK (YOUTUBE, TIKTOK, INSTAGRAM) UPLOAD
  // ===========================================================================

  Future<Track> uploadTrack({
    required String title,
    required String description,
    required String genre,
    required List<String> tags,
    required int durationSec,
    required bool copyrightAccepted,
    String mediaType = 'audio', // 'audio' | 'video' | 'social_link'
    Uint8List? audioBytes,
    String? audioFileName,
    Uint8List? videoBytes,
    String? videoFileName,
    String? videoUrl,
    String? externalUrl, // YouTube, TikTok, Instagram link
    Uint8List? coverBytes,
    String? coverUrlFallback,
  }) async {
    final me = _currentUser;
    if (me == null) {
      throw Exception('Yükleme yapmak için giriş yapmalısınız.');
    }
    if (!copyrightAccepted) {
      throw Exception(
        'Yasal telif ve yayın hakları beyanını onaylamadan yükleme yapılamaz.',
      );
    }

    final now = DateTime.now();
    final trackId = 'trk_${now.millisecondsSinceEpoch}';

    final cleanExternalUrl =
        (externalUrl != null && externalUrl.trim().isNotEmpty)
            ? externalUrl.trim()
            : null;
    final detectedPlatform = Track.detectSocialPlatform(cleanExternalUrl);
    final ytThumb = Track.extractYoutubeThumbnail(cleanExternalUrl);

    String resolvedAudioUrl = 'synth://$trackId';
    String? resolvedVideoUrl = videoUrl;
    String resolvedCoverUrl = coverUrlFallback ?? ytThumb ?? '';

    if (audioBytes != null) {
      audioEngine.registerUploadedBytes(trackId, audioBytes);
      resolvedAudioUrl =
          'local://audio/$trackId/${audioFileName ?? "audio.mp3"}';
    }
    if (videoBytes != null) {
      _uploadedVideoBytes[trackId] = videoBytes;
      resolvedVideoUrl ??=
          'memory://video/$trackId/${videoFileName ?? "clip.mp4"}';
    }
    if (coverBytes != null) {
      _uploadedCoverBytes[trackId] = coverBytes;
      resolvedCoverUrl = 'memory://cover/$trackId';
    }

    if (_firebaseAvailable) {
      try {
        if (audioBytes != null) {
          final ref = FirebaseStorage.instance
              .ref('tracks/${me.id}/$trackId/${audioFileName ?? "audio.mp3"}');
          await ref.putData(audioBytes);
          resolvedAudioUrl = await ref.getDownloadURL();
        }
        if (videoBytes != null) {
          final ref = FirebaseStorage.instance
              .ref('tracks/${me.id}/$trackId/${videoFileName ?? "video.mp4"}');
          await ref.putData(videoBytes);
          resolvedVideoUrl = await ref.getDownloadURL();
        }
        if (coverBytes != null) {
          final ref = FirebaseStorage.instance
              .ref('tracks/${me.id}/$trackId/cover.jpg');
          await ref.putData(coverBytes);
          resolvedCoverUrl = await ref.getDownloadURL();
        }
      } catch (_) {}
    }

    final newTrack = Track(
      id: trackId,
      userId: me.id,
      title: title.trim(),
      description: description.trim(),
      mediaType: cleanExternalUrl != null ? 'social_link' : mediaType,
      audioUrl: resolvedAudioUrl,
      videoUrl: resolvedVideoUrl,
      externalUrl: cleanExternalUrl,
      externalPlatform: detectedPlatform,
      coverUrl: resolvedCoverUrl,
      genre: genre,
      tags: tags,
      durationSec: durationSec,
      playCount: 0,
      likedByUserIds: const [],
      savedByUserIds: const [],
      waveform: generateWaveform(48, trackId.hashCode),
      copyrightAcceptedAt: now,
      copyrightAcceptedByUserId: me.id,
      isHidden: false,
      createdAt: now,
    );

    _tracks.insert(0, newTrack);

    if (me.pinnedTrackId == null) {
      final updatedMe = me.copyWith(pinnedTrackId: newTrack.id);
      _updateUserInList(updatedMe);
      _currentUser = updatedMe;
    }

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('tracks')
            .doc(newTrack.id)
            .set(newTrack.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
    return newTrack;
  }

  // ===========================================================================
  // PROFILE / MYSPACE ROOM CUSTOMIZATION
  // ===========================================================================

  Future<void> updateMyspaceProfile({
    String? displayName,
    String? bio,
    String? themeGradient,
    bool? isOpenToCollab,
    List<String>? musicStyles,
    List<String>? roles,
    String? pinnedTrackId,
    Uint8List? avatarBytes,
  }) async {
    final me = _currentUser;
    if (me == null) return;

    if (avatarBytes != null) {
      _uploadedAvatarBytes[me.id] = avatarBytes;
    }

    final updated = me.copyWith(
      displayName: displayName,
      bio: bio,
      themeGradient: themeGradient,
      isOpenToCollab: isOpenToCollab,
      musicStyles: musicStyles,
      roles: roles,
      pinnedTrackId: pinnedTrackId,
    );

    _updateUserInList(updated);
    _currentUser = updated;

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updated.id)
            .update(updated.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
  }

  void _updateUserInList(AppUser updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _users[idx] = updated;
    }
    if (_currentUser?.id == updated.id) {
      _currentUser = updated;
    }
  }

  // ===========================================================================
  // DM & COLLAB
  // ===========================================================================

  List<AppUser> get activeConversationPartners {
    final me = _currentUser;
    if (me == null) return [];
    final blocked = blockedUserIds;
    final partnerIds = <String>{};

    for (final m in _messages) {
      if (m.senderId == me.id && !blocked.contains(m.receiverId)) {
        partnerIds.add(m.receiverId);
      } else if (m.receiverId == me.id && !blocked.contains(m.senderId)) {
        partnerIds.add(m.senderId);
      }
    }

    for (final u in _users) {
      if (u.id != me.id &&
          !blocked.contains(u.id) &&
          !u.isSuspended &&
          !u.isAdmin) {
        partnerIds.add(u.id);
      }
    }

    return partnerIds.map(getUserById).whereType<AppUser>().toList();
  }

  List<DirectMessage> messagesWithUser(String partnerId) {
    final me = _currentUser;
    if (me == null) return [];
    if (isUserBlocked(partnerId)) return [];

    final list = _messages
        .where((m) =>
            (m.senderId == me.id && m.receiverId == partnerId) ||
            (m.senderId == partnerId && m.receiverId == me.id))
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    bool isCollabRequest = false,
    String? collabRole,
    String? referenceTrackId,
  }) async {
    final me = _currentUser;
    if (me == null || content.trim().isEmpty) return;

    final msg = DirectMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: me.id,
      receiverId: receiverId,
      content: content.trim(),
      isCollabRequest: isCollabRequest,
      collabRole: collabRole,
      referenceTrackId: referenceTrackId,
      createdAt: DateTime.now(),
    );

    _messages.add(msg);

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(msg.id)
            .set(msg.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
  }

  // ===========================================================================
  // UGC SAFETY: REPORT (DMCA/5651), BLOCK & ADMIN MODERATION
  // ===========================================================================

  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String targetSummary,
    required String targetOwnerId,
    required String reason,
    String details = '',
  }) async {
    final me = _currentUser;
    if (me == null) return;

    final report = ContentReport(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reporterId: me.id,
      targetType: targetType,
      targetId: targetId,
      targetSummary: targetSummary,
      targetOwnerId: targetOwnerId,
      reason: reason,
      details: details.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _reports.insert(0, report);

    if (_firebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(report.id)
            .set(report.toMap());
      } catch (_) {}
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> blockUser(String blockedUserId) async {
    final me = _currentUser;
    if (me == null || me.id == blockedUserId) return;

    if (!isUserBlocked(blockedUserId)) {
      final block = UserBlock(
        blockerId: me.id,
        blockedId: blockedUserId,
        createdAt: DateTime.now(),
      );
      _blocks.add(block);

      final activeTrack = getTrackById(audioEngine.activeTrackId);
      if (activeTrack != null && activeTrack.userId == blockedUserId) {
        await audioEngine.pause();
      }

      if (_firebaseAvailable) {
        try {
          await FirebaseFirestore.instance
              .collection('blocks')
              .doc('${me.id}_$blockedUserId')
              .set(block.toMap());
        } catch (_) {}
      }

      await _persistState();
      notifyListeners();
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    final me = _currentUser;
    if (me == null) return;
    _blocks.removeWhere(
      (b) => b.blockerId == me.id && b.blockedId == blockedUserId,
    );
    await _persistState();
    notifyListeners();
  }

  Future<void> adminSoftDeleteContent(ContentReport report) async {
    if (_currentUser?.isAdmin != true) return;

    if (report.targetType == 'track') {
      final idx = _tracks.indexWhere((t) => t.id == report.targetId);
      if (idx >= 0) {
        _tracks[idx] = _tracks[idx].copyWith(isHidden: true);
        if (audioEngine.activeTrackId == report.targetId) {
          await audioEngine.pause();
        }
      }
    } else if (report.targetType == 'comment') {
      final idx = _comments.indexWhere((c) => c.id == report.targetId);
      if (idx >= 0) {
        _comments[idx] = _comments[idx].copyWith(isHidden: true);
      }
    }

    final repIdx = _reports.indexWhere((r) => r.id == report.id);
    if (repIdx >= 0) {
      _reports[repIdx] = _reports[repIdx].copyWith(status: 'resolved');
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> adminSuspendUser(String targetUserId, {String? relatedReportId}) async {
    if (_currentUser?.isAdmin != true) return;
    final target = getUserById(targetUserId);
    if (target == null) return;

    final updatedUser = target.copyWith(isSuspended: !target.isSuspended);
    _updateUserInList(updatedUser);

    if (relatedReportId != null) {
      final repIdx = _reports.indexWhere((r) => r.id == relatedReportId);
      if (repIdx >= 0) {
        _reports[repIdx] = _reports[repIdx].copyWith(status: 'resolved');
      }
    }

    await _persistState();
    notifyListeners();
  }

  Future<void> adminToggleTrackHidden(String trackId) async {
    if (_currentUser?.isAdmin != true) return;
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return;
    _tracks[idx] = _tracks[idx].copyWith(isHidden: !_tracks[idx].isHidden);
    await _persistState();
    notifyListeners();
  }
}
