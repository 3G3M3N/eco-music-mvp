import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onOpenStandaloneAdmin;

  const AuthScreen({
    super.key,
    required this.appState,
    this.onOpenStandaloneAdmin,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _acceptedTermsAndPrivacy = false;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _avatarBytes;

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Set<String> _selectedMusicStyles = {'Indie', 'Alternatif Rock'};
  final Set<String> _selectedRoles = {'Vokal'};

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _avatarBytes = result.files.first.bytes);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        await widget.appState.signUpWithEmail(
          username: _usernameController.text,
          displayName: _displayNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          musicStyles: _selectedMusicStyles.toList(),
          roles: _selectedRoles.toList(),
          acceptedTermsAndPrivacy: _acceptedTermsAndPrivacy,
          avatarBytes: _avatarBytes,
        );
      } else {
        await widget.appState.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLegalTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kullanım Koşulları ve Gizlilik Politikası',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '1. Telif ve İçerik Sorumluluğu\n'
            'eco üzerinde paylaşılan tüm ses, video ve görsel içeriklerin telif hakları yükleyen kullanıcıya aittir.\n\n'
            '2. Uyar-Kaldır (5651 & DMCA)\n'
            'Telif hakkı ihlali, uygunsuz içerik veya spam bildirimleri moderasyon ekibi tarafından incelenir ve ihlal tespit edilen içerikler yayından kaldırılır.\n\n'
            '3. Topluluk Güvenliği\n'
            'Kullanıcılar diledikleri hesabı engelleyebilir veya raporlayabilir. Kuralları ihlal eden hesaplar askıya alınır.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Kapat',
              style: TextStyle(color: Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit =
        !_isLoading && (!_isSignUp || _acceptedTermsAndPrivacy);

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'eco.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bağımsız müzik, ham demolar ve iş birliği.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0F14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070709),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isSignUp = false;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isSignUp
                                        ? const Color(0xFF1C1E28)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      color: !_isSignUp
                                          ? Colors.white
                                          : Colors.white38,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isSignUp = true;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isSignUp
                                        ? const Color(0xFF1C1E28)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Kayıt Ol',
                                    style: TextStyle(
                                      color: _isSignUp
                                          ? Colors.white
                                          : Colors.white38,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_isSignUp) ...[
                        Center(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: const Color(0xFF191B24),
                                  backgroundImage: _avatarBytes != null
                                      ? MemoryImage(_avatarBytes!)
                                      : null,
                                  child: _avatarBytes == null
                                      ? const Icon(
                                          Icons.add_a_photo_outlined,
                                          color: Colors.white54,
                                          size: 22,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Profil Fotoğrafı Ekle',
                                  style: TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          controller: _usernameController,
                          hint: 'Kullanıcı adı (örn: kaan)',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildInput(
                          controller: _displayNameController,
                          hint: 'Görünür Ad / Sanatçı Adı',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                      ],

                      _buildInput(
                        controller: _emailController,
                        hint: 'E-posta adresi',
                        icon: Icons.mail_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildInput(
                        controller: _passwordController,
                        hint: 'Şifre',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),

                      if (_isSignUp) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Yaptığın Müzik Türleri (Rap, Indie, Alternatif Rock vb.)',
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
                            final selected =
                                _selectedMusicStyles.contains(style);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected &&
                                      _selectedMusicStyles.length > 1) {
                                    _selectedMusicStyles.remove(style);
                                  } else {
                                    _selectedMusicStyles.add(style);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  style,
                                  style: TextStyle(
                                    color:
                                        selected ? Colors.white : Colors.white54,
                                    fontSize: 11.5,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rol / Enstrüman (İsteğe Bağlı)',
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
                            final selected = _selectedRoles.contains(role);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedRoles.remove(role);
                                  } else {
                                    _selectedRoles.add(role);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF10B981)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color:
                                        selected ? Colors.white : Colors.white54,
                                    fontSize: 11.5,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _acceptedTermsAndPrivacy,
                                activeColor: const Color(0xFF8B5CF6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() =>
                                      _acceptedTermsAndPrivacy = val ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                children: [
                                  GestureDetector(
                                    onTap: _showLegalTermsDialog,
                                    child: const Text(
                                      'Kullanım Koşulları ve Gizlilik Politikası',
                                      style: TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _acceptedTermsAndPrivacy =
                                            !_acceptedTermsAndPrivacy),
                                    child: const Text(
                                      '\'nı kabul ediyorum.',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFF43F5E),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 18),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.07),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          onPressed: canSubmit ? _submit : null,
                          child: Text(
                            _isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.onOpenStandaloneAdmin != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: widget.onOpenStandaloneAdmin,
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Colors.white24,
                      ),
                      label: const Text(
                        'Yönetici Konsolu',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        filled: true,
        fillColor: const Color(0xFF070709),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        ),
      ),
    );
  }
}
