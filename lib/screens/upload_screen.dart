import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/report_dialog.dart';

class UploadScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onUploadSuccess;

  const UploadScreen({
    super.key,
    required this.appState,
    required this.onUploadSuccess,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _socialLinkController = TextEditingController();

  String _mediaType = 'social_link'; // 'social_link' | 'video' | 'audio'
  String _selectedGenre = 'Cover';
  final Set<String> _selectedTags = {'#cover'};

  Uint8List? _pickedAudioBytes;
  String? _pickedAudioName;

  Uint8List? _pickedVideoBytes;
  String? _pickedVideoName;

  Uint8List? _pickedCoverBytes;
  String? _pickedCoverName;

  bool _copyrightAccepted = false;
  bool _isUploading = false;

  static const List<String> _defaultTags = [
    '#cover',
    '#demo',
    '#orijinal',
    '#akustik',
    '#canlı',
    '#taslak',
    '#collab',
    '#beat',
    '#vokal',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _socialLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedAudioBytes = file.bytes;
          _pickedAudioName = file.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'webm'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedVideoBytes = file.bytes;
          _pickedVideoName = file.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedCoverBytes = file.bytes;
          _pickedCoverName = file.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitUpload() async {
    if (!_copyrightAccepted) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen parça veya cover adını girin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_mediaType == 'social_link' &&
        _socialLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Lütfen geçerli bir YouTube, TikTok veya Instagram linki yapıştırın.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await widget.appState.uploadTrack(
        title: _titleController.text,
        description: _descriptionController.text,
        genre: _selectedGenre,
        tags: _selectedTags.toList(),
        durationSec: 180, // Gerçek video/ses oynatıcı süreyi otomatik belirler
        copyrightAccepted: _copyrightAccepted,
        mediaType: _mediaType,
        audioBytes: _pickedAudioBytes,
        audioFileName: _pickedAudioName,
        videoBytes: _pickedVideoBytes,
        videoFileName: _pickedVideoName,
        externalUrl: _mediaType == 'social_link'
            ? _socialLinkController.text.trim()
            : null,
        coverBytes: _pickedCoverBytes,
      );

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        _socialLinkController.clear();
        setState(() {
          _pickedAudioBytes = null;
          _pickedAudioName = null;
          _pickedVideoBytes = null;
          _pickedVideoName = null;
          _pickedCoverBytes = null;
          _pickedCoverName = null;
          _copyrightAccepted = false;
        });
        widget.onUploadSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canUpload = _copyrightAccepted && !_isUploading;
    final detectedPlatform =
        Track.detectSocialPlatform(_socialLinkController.text);
    final ytThumb = Track.extractYoutubeThumbnail(_socialLinkController.text);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0F14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Cover, Video veya Demo Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3-Way Format Selector: TikTok/IG/YT Link | Video + Ses | Sadece Ses
                  Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070709),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab(
                          id: 'social_link',
                          icon: Icons.link_rounded,
                          label: 'YouTube / TikTok / IG',
                        ),
                        _buildModeTab(
                          id: 'video',
                          icon: Icons.videocam_rounded,
                          label: 'Video Dosyası',
                        ),
                        _buildModeTab(
                          id: 'audio',
                          icon: Icons.graphic_eq_rounded,
                          label: 'Sadece Ses',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_mediaType == 'social_link') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070709),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: detectedPlatform != null
                              ? const Color(0xFF8B5CF6)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.ondemand_video_rounded,
                                color: Color(0xFF8B5CF6),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'YouTube, TikTok veya Instagram Reels Linki',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              if (detectedPlatform != null)
                                SocialPlatformBadge(platform: detectedPlatform),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _socialLinkController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'https://www.youtube.com/watch?v=... veya tiktok.com/...',
                              hintStyle: const TextStyle(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              filled: true,
                              fillColor: const Color(0xFF0E0F14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if (ytThumb != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 140,
                                width: double.infinity,
                                child: Image.network(
                                  ytThumb,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      if (_mediaType != 'social_link') ...[
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _mediaType == 'video'
                                ? _pickVideoFile
                                : _pickAudioFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF070709),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (_pickedAudioName != null ||
                                          _pickedVideoName != null)
                                      ? const Color(0xFF10B981)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _mediaType == 'video'
                                        ? Icons.videocam_outlined
                                        : Icons.audio_file_outlined,
                                    color: const Color(0xFF8B5CF6),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _mediaType == 'video'
                                        ? (_pickedVideoName ??
                                            'Video Seç (MP4/MOV)')
                                        : (_pickedAudioName ??
                                            'Ses Seç (MP3/WAV/M4A)'),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickCoverImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070709),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _pickedCoverBytes != null
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_pickedCoverBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      _pickedCoverBytes!,
                                      height: 24,
                                      width: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.face_retouching_natural_rounded,
                                    color: Colors.white54,
                                    size: 24,
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  _pickedCoverName ??
                                      'Özel Kapak Fotoğrafı (Opsiyonel)',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Parça / Cover adı',
                      hintStyle:
                          const TextStyle(color: Colors.white30, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(13),
                      filled: true,
                      fillColor: const Color(0xFF070709),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Açıklama, orijinal eser veya iş birliği notu...',
                      hintStyle:
                          const TextStyle(color: Colors.white30, fontSize: 12.5),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(13),
                      filled: true,
                      fillColor: const Color(0xFF070709),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedGenre,
                    dropdownColor: const Color(0xFF161821),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Kategori / Müzik Türü',
                      labelStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF070709),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: AppState.genres
                        .where((g) => g != 'Tümü')
                        .map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedGenre = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _defaultTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected && _selectedTags.length > 1) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070709),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _copyrightAccepted
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _copyrightAccepted,
                            activeColor: const Color(0xFF8B5CF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() => _copyrightAccepted = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _copyrightAccepted = !_copyrightAccepted;
                              });
                            },
                            child: const Text(
                              'Yüklediğim ses ve görsel içeriğin tüm telif ve yayın haklarına sahip olduğumu, üçüncü şahıs haklarını ihlal etmediğini beyan ve kabul ederim.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        disabledForegroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      onPressed: canUpload ? _submitUpload : null,
                      child: const Text(
                        'Paylaş',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String id,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _mediaType == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mediaType = id),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1C1E28) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white38,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
