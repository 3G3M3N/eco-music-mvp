import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myspace_music/services/app_state.dart';
import 'package:myspace_music/widgets/social_video_embed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('eco Production MVP End-to-End Flow: Clean Start, Music Styles, TikTok/IG/YouTube Social Links, Early Supporter, Timestamped Comments, Block & Standalone Admin', () async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.initialize();

    expect(appState.currentUser, isNull);
    expect(appState.feedTracks, isEmpty);

    // 1. Yapılan Müzik Türleri (Rap, Indie, Alternatif Rock) + Rol ile kayıt
    await appState.signUpWithEmail(
      username: 'kaan',
      displayName: 'Kaan',
      email: 'kaan@eco.fm',
      password: 'password123',
      musicStyles: ['Indie', 'Alternatif Rock', 'Rap'],
      roles: ['Gitarist'],
      acceptedTermsAndPrivacy: true,
    );
    final user1 = appState.currentUser!;
    expect(user1.musicStyles, containsAll(['Indie', 'Alternatif Rock', 'Rap']));

    // 2. TikTok / Instagram / YouTube Linki ile doğrudan kayıt paylaşımı
    final tiktokTrack = await appState.uploadTrack(
      title: 'Gece Kaydı (TikTok Kesiti)',
      description: 'TikTok performansım',
      genre: 'Alternatif Rock',
      tags: ['#demo', '#orijinal'],
      durationSec: 45,
      copyrightAccepted: true,
      mediaType: 'social_link',
      externalUrl: 'https://www.tiktok.com/@kaan/video/734918273',
    );
    expect(tiktokTrack.externalPlatform, 'tiktok');
    expect(tiktokTrack.hasExternalLink, isTrue);

    final ytTrack = await appState.uploadTrack(
      title: 'Stüdyo Canlı (YouTube)',
      description: 'YouTube Shorts',
      genre: 'Indie',
      tags: ['#demo'],
      durationSec: 50,
      copyrightAccepted: true,
      mediaType: 'social_link',
      externalUrl: 'https://youtu.be/dQw4w9WgXcQ',
    );
    expect(ytTrack.externalPlatform, 'youtube');
    expect(ytTrack.coverUrl, contains('img.youtube.com/vi/dQw4w9WgXcQ'));
    expect(
      SocialVideoEmbedPlayer.resolveEmbedUrl(ytTrack.externalUrl!),
      'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&rel=0&modestbranding=1&playsinline=1',
    );
    expect(
      SocialVideoEmbedPlayer.resolveEmbedUrl(tiktokTrack.externalUrl!),
      'https://www.tiktok.com/embed/v2/734918273',
    );

    // 3. 2. sanatçı kaydı ve <100 takipçili sanatçıyı takip ederek Early Supporter rozeti kazanma
    await appState.signOut();
    await appState.signUpWithEmail(
      username: 'selin',
      displayName: 'Selin',
      email: 'selin@eco.fm',
      password: 'password123',
      musicStyles: ['Indie', 'Pop'],
      roles: ['Vokal'],
      acceptedTermsAndPrivacy: true,
    );
    final user2 = appState.currentUser!;

    final earnedEarly = await appState.toggleFollow(user1.id);
    expect(earnedEarly, isTrue);
    expect(
      appState.isEarlySupporterOf(followerId: user2.id, artistId: user1.id),
      isTrue,
    );

    // 4. 0:24 saniyesine nokta atışı yorum bırakma
    await appState.addTimestampedComment(
      trackId: tiktokTrack.id,
      content: '0:24 geçişi çok iyi',
      timestampSec: 24,
    );
    expect(appState.commentsForTrack(tiktokTrack.id).first.timestampSec, 24);

    // 5. Raporlama (DMCA/5651) ve Bağımsız Admin Konsolu (admin@eco.fm) ile Soft-Delete
    await appState.submitReport(
      targetType: 'track',
      targetId: tiktokTrack.id,
      targetSummary: tiktokTrack.title,
      targetOwnerId: user1.id,
      reason: 'Telif Hakkı İhlali (DMCA/5651)',
    );

    await appState.signOut();
    await appState.signInWithEmail(
      email: 'admin@eco.fm',
      password: 'admin',
    );
    expect(appState.currentUser!.isAdmin, isTrue);

    final report = appState.allReports.first;
    await appState.adminSoftDeleteContent(report);
    expect(appState.getTrackById(tiktokTrack.id)!.isHidden, isTrue);
  });
}
