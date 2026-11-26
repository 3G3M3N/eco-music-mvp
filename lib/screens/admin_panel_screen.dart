import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';

/// Bağımsız (Ayrı Açılan) Admin Moderasyon Konsolu
class AdminPanelScreen extends StatefulWidget {
  final AppState appState;
  const AdminPanelScreen({super.key, required this.appState});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _adminEmailCtrl = TextEditingController(text: 'admin@eco.fm');
  final _adminPassCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginAsAdmin() async {
    setState(() => _error = null);
    try {
      await widget.appState.signInWithEmail(
        email: _adminEmailCtrl.text,
        password: _adminPassCtrl.text.isEmpty ? 'admin' : _adminPassCtrl.text,
      );
      if (widget.appState.currentUser?.isAdmin != true) {
        setState(() => _error = 'Bu hesap yönetici (role: "admin") yetkisine sahip değil.');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final me = widget.appState.currentUser;
        final isAuthorized = me != null && me.isAdmin;

        return Scaffold(
          backgroundColor: const Color(0xFF070709),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C0D12),
            elevation: 0,
            title: Row(
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFFFBBF24), size: 19),
                SizedBox(width: 8),
                Text(
                  'eco. Yönetici & Moderasyon Konsolu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: !isAuthorized
              ? _buildAdminLoginGate()
              : _buildModerationDashboard(context),
        );
      },
    );
  }

  Widget _buildAdminLoginGate() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(22),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yönetici Girişi (role: "admin")',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Moderasyon paneline erişmek için yetkili yönetici hesabıyla giriş yapın (admin@eco.fm).',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminEmailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'admin@eco.fm',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: const Color(0xFF070709),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _adminPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Yönetici şifresi',
                  hintStyle: const TextStyle(color: Colors.white30),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: const Color(0xFF070709),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loginAsAdmin,
                child: const Text('Konsolu Aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModerationDashboard(BuildContext context) {
    final appState = widget.appState;
    final reports = appState.allReports;
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ŞİKAYET EDİLEN İÇERİKLER (${reports.length})',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                if (reports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0F14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Bekleyen bildirim bulunmuyor.',
                      style: TextStyle(color: Colors.white38, fontSize: 12.5),
                    ),
                  )
                else
                  for (final report in reports)
                    Builder(
                      builder: (context) {
                        final reporter =
                            appState.getUserById(report.reporterId);
                        final targetOwner =
                            appState.getUserById(report.targetOwnerId);
                        final isResolved = report.status == 'resolved';
                        final isSuspended = targetOwner?.isSuspended ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E0F14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isResolved
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF43F5E)
                                      .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF43F5E)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      report.reason,
                                      style: const TextStyle(
                                        color: Color(0xFFF43F5E),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${report.targetType.toUpperCase()} • ${dateFmt.format(report.createdAt)}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isResolved ? 'Çözüldü' : 'Bekliyor',
                                    style: TextStyle(
                                      color: isResolved
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFFBBF24),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.targetSummary,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (report.details.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  report.details,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Bildiren: @${reporter?.username ?? report.reporterId}  •  Hedef Hesap: @${targetOwner?.username ?? report.targetOwnerId}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFF43F5E)
                                          .withValues(alpha: 0.16),
                                      foregroundColor: const Color(0xFFF43F5E),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        appState.adminSoftDeleteContent(report),
                                    icon: const Icon(
                                      Icons.visibility_off_outlined,
                                      size: 15,
                                    ),
                                    label: const Text(
                                      'Yayından Kaldır (is_hidden: true)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.15),
                                      ),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => appState.adminSuspendUser(
                                      report.targetOwnerId,
                                      relatedReportId: report.id,
                                    ),
                                    icon: const Icon(
                                      Icons.person_off_outlined,
                                      size: 15,
                                    ),
                                    label: Text(
                                      isSuspended
                                          ? 'Askıyı Kaldır'
                                          : 'Kullanıcıyı Askıya Al',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                const SizedBox(height: 22),
                Text(
                  'YÜKLENEN KAYITLAR & TELİF ONAY LOGLARI (${appState.allTracks.length})',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                for (final track in appState.allTracks)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0F14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: track.isHidden
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${track.title} ${track.isHidden ? "(Gizlendi)" : ""}',
                                style: TextStyle(
                                  color: track.isHidden
                                      ? const Color(0xFFF43F5E)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Telif Onayı: ${dateFmt.format(track.copyrightAcceptedAt)}  •  User ID: ${track.copyrightAcceptedByUserId}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              appState.adminToggleTrackHidden(track.id),
                          child: Text(
                            track.isHidden ? 'Yayına Al' : 'Gizle',
                            style: TextStyle(
                              color: track.isHidden
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
