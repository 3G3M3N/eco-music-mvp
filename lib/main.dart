import 'package:flutter/material.dart';
import 'models/models.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/myspace_profile_screen.dart';
import 'screens/upload_screen.dart';
import 'services/app_state.dart';
import 'services/audio_engine.dart';
import 'widgets/report_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runApp(EcoApp(appState: appState));
}

class EcoApp extends StatelessWidget {
  final AppState appState;
  const EcoApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eco.',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050507),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF0B0C10),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/admin': (ctx) => AdminPanelScreen(appState: appState),
      },
      home: MainShell(appState: appState),
    );
  }
}

class MainShell extends StatefulWidget {
  final AppState appState;
  const MainShell({super.key, required this.appState});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0; // 0: Keşfet, 1: Paylaş, 2: Mesajlar, 3: Oda (Profil)
  String? _viewedProfileUserId;
  String? _chatPartnerId;
  String? _chatReferenceTrackId;

  void _openArtistProfile(AppUser artist) {
    setState(() {
      _viewedProfileUserId = artist.id;
      _selectedIndex = 3;
    });
  }

  void _startCollabChat(AppUser artist, {Track? referenceTrack}) {
    setState(() {
      _chatPartnerId = artist.id;
      _chatReferenceTrackId = referenceTrack?.id;
      _selectedIndex = 2;
    });
  }

  void _openStandaloneAdminConsole() {
    Navigator.of(context).pushNamed('/admin');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final me = widget.appState.currentUser;
        if (me == null) {
          return AuthScreen(
            appState: widget.appState,
            onOpenStandaloneAdmin: _openStandaloneAdminConsole,
          );
        }

        final activeProfileId = _viewedProfileUserId ?? me.id;

        final pages = [
          FeedScreen(
            appState: widget.appState,
            onOpenArtistProfile: _openArtistProfile,
            onStartCollabChat: _startCollabChat,
            onGoToUpload: () => setState(() => _selectedIndex = 1),
          ),
          UploadScreen(
            appState: widget.appState,
            onUploadSuccess: () => setState(() => _selectedIndex = 0),
          ),
          MessagesScreen(
            appState: widget.appState,
            initialPartnerId: _chatPartnerId,
            initialReferenceTrackId: _chatReferenceTrackId,
            onOpenArtistProfile: _openArtistProfile,
          ),
          MyspaceProfileScreen(
            appState: widget.appState,
            viewedUserId: activeProfileId,
            onBackToOwnProfile: activeProfileId != me.id
                ? () => setState(() => _viewedProfileUserId = me.id)
                : null,
            onStartCollabChat: _startCollabChat,
            onOpenStandaloneAdmin: _openStandaloneAdminConsole,
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF050507),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF050507),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: Color(0xFF050507),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'eco.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const Spacer(),
                        if (me.isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFBBF24),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _openStandaloneAdminConsole,
                              icon: const Icon(Icons.shield_outlined, size: 15),
                              label: const Text(
                                'Moderasyon',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _viewedProfileUserId = me.id;
                              _selectedIndex = 3;
                            });
                          },
                          child: UserAvatar(
                            user: me,
                            appState: widget.appState,
                            radius: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(child: pages[_selectedIndex]),
              _buildSlimMiniPlayerBar(),
            ],
          ),
          bottomNavigationBar: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF08090D),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSlimNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Akış',
                      ),
                      _buildSlimNavItem(
                        index: 1,
                        icon: Icons.add_box_outlined,
                        activeIcon: Icons.add_box_rounded,
                        label: 'Paylaş',
                      ),
                      _buildSlimNavItem(
                        index: 2,
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Mesajlar',
                      ),
                      _buildSlimNavItem(
                        index: 3,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profil',
                        onTapOverride: () {
                          setState(() {
                            _viewedProfileUserId = me.id;
                            _selectedIndex = 3;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlimNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: onTapOverride ?? () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white38,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlimMiniPlayerBar() {
    return ListenableBuilder(
      listenable: widget.appState.audioEngine,
      builder: (context, _) {
        final audio = widget.appState.audioEngine;
        final activeTrack = widget.appState.getTrackById(audio.activeTrackId);
        if (activeTrack == null || activeTrack.hasExternalLink) {
          return const SizedBox.shrink();
        }

        final artist = widget.appState.getUserById(activeTrack.userId);
        final progress = audio.progressForTrack(activeTrack);

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F15),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => audio.togglePlay(activeTrack),
                        child: Icon(
                          audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${activeTrack.title}  •  ${artist?.displayName ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${AudioEngine.formatDuration(audio.currentSecondInt)} / ${AudioEngine.formatDuration(activeTrack.durationSec)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
