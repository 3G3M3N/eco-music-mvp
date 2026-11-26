import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/report_dialog.dart';

class MessagesScreen extends StatefulWidget {
  final AppState appState;
  final String? initialPartnerId;
  final String? initialReferenceTrackId;
  final ValueChanged<AppUser> onOpenArtistProfile;

  const MessagesScreen({
    super.key,
    required this.appState,
    this.initialPartnerId,
    this.initialReferenceTrackId,
    required this.onOpenArtistProfile,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? _selectedPartnerId;
  bool _sendAsCollabRequest = false;
  String _selectedCollabRole = 'Vokal';
  String? _referenceTrackId;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.initialPartnerId;
    _referenceTrackId = widget.initialReferenceTrackId;
    if (_referenceTrackId != null) {
      _sendAsCollabRequest = true;
    }
  }

  @override
  void didUpdateWidget(covariant MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPartnerId != null &&
        widget.initialPartnerId != oldWidget.initialPartnerId) {
      _selectedPartnerId = widget.initialPartnerId;
    }
    if (widget.initialReferenceTrackId != null &&
        widget.initialReferenceTrackId != oldWidget.initialReferenceTrackId) {
      _referenceTrackId = widget.initialReferenceTrackId;
      _sendAsCollabRequest = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(AppUser partner) async {
    if (_messageController.text.trim().isEmpty) return;
    await widget.appState.sendMessage(
      receiverId: partner.id,
      content: _messageController.text,
      isCollabRequest: _sendAsCollabRequest,
      collabRole: _sendAsCollabRequest ? _selectedCollabRole : null,
      referenceTrackId: _sendAsCollabRequest ? _referenceTrackId : null,
    );
    _messageController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final partners = widget.appState.activeConversationPartners;
    if (partners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white38,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Henüz mesaj yok',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keşfet akışındaki sanatçıların profillerinden veya parça kartlarından iş birliği teklifi başlatabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final activePartner = partners.firstWhere(
      (u) => u.id == _selectedPartnerId,
      orElse: () => partners.first,
    );
    _selectedPartnerId = activePartner.id;

    final messages = widget.appState.messagesWithUser(activePartner.id);
    final refTrack = widget.appState.getTrackById(_referenceTrackId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 680;

        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 240,
                child: _buildPartnerSidebar(partners, activePartner),
              ),
              VerticalDivider(
                width: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              Expanded(
                child: _buildChatArea(
                  context: context,
                  partner: activePartner,
                  messages: messages,
                  refTrack: refTrack,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 62,
              child: _buildMobilePartnerStrip(partners, activePartner),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            Expanded(
              child: _buildChatArea(
                context: context,
                partner: activePartner,
                messages: messages,
                refTrack: refTrack,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartnerSidebar(List<AppUser> partners, AppUser activePartner) {
    return Container(
      color: const Color(0xFF0A0B0F),
      child: ListView.builder(
        itemCount: partners.length,
        itemBuilder: (context, index) {
          final u = partners[index];
          final isSelected = u.id == activePartner.id;
          final thread = widget.appState.messagesWithUser(u.id);
          final lastMsg = thread.isNotEmpty ? thread.last : null;

          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: Colors.white.withValues(alpha: 0.05),
            onTap: () => setState(() => _selectedPartnerId = u.id),
            leading: UserAvatar(
              user: u,
              appState: widget.appState,
              radius: 18,
            ),
            title: Text(
              u.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              lastMsg?.content ?? '@${u.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobilePartnerStrip(
    List<AppUser> partners,
    AppUser activePartner,
  ) {
    return Container(
      color: const Color(0xFF0A0B0F),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: partners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final u = partners[index];
          final isSelected = u.id == activePartner.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPartnerId = u.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    user: u,
                    appState: widget.appState,
                    radius: 13,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    u.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatArea({
    required BuildContext context,
    required AppUser partner,
    required List<DirectMessage> messages,
    required Track? refTrack,
  }) {
    final me = widget.appState.currentUser;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F14),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onOpenArtistProfile(partner),
                child: UserAvatar(
                  user: partner,
                  appState: widget.appState,
                  radius: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onOpenArtistProfile(partner),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        '@${partner.username}  •  ${partner.roles.join(", ")}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                color: const Color(0xFF161821),
                onSelected: (val) async {
                  if (val == 'block') {
                    await widget.appState.blockUser(partner.id);
                    setState(() => _selectedPartnerId = null);
                  } else if (val == 'report') {
                    await showReportContentDialog(
                      context: context,
                      appState: widget.appState,
                      targetType: 'user',
                      targetId: partner.id,
                      targetSummary: '@${partner.username}',
                      targetOwnerId: partner.id,
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Text(
                      'Kullanıcıyı Bildir',
                      style: TextStyle(color: Colors.white, fontSize: 13),
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
        ),

        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    '@${partner.username} ile sohbet başlat.',
                    style: const TextStyle(color: Colors.white30, fontSize: 12.5),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.senderId == me?.id;
                    final linkedTrack =
                        widget.appState.getTrackById(msg.referenceTrackId);

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isCollabRequest
                                ? const Color(0xFF1A142D)
                                : (isMine
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF161822)),
                            borderRadius: BorderRadius.circular(14),
                            border: msg.isCollabRequest
                                ? Border.all(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.6),
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.isCollabRequest) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.handshake_outlined,
                                      color: Color(0xFFC4B5FD),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'COLLAB TEKLİFİ${msg.collabRole != null ? " • ${msg.collabRole!.toUpperCase()}" : ""}',
                                      style: const TextStyle(
                                        color: Color(0xFFC4B5FD),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                              ],
                              Text(
                                msg.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              if (linkedTrack != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => widget.appState.audioEngine
                                      .togglePlay(linkedTrack),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Color(0xFF8B5CF6),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            linkedTrack.title,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0F14),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                        () => _sendAsCollabRequest = !_sendAsCollabRequest),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _sendAsCollabRequest
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: _sendAsCollabRequest
                              ? const Color(0xFF8B5CF6)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 13,
                            color: _sendAsCollabRequest
                                ? const Color(0xFFC4B5FD)
                                : Colors.white54,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Collab Teklifi',
                            style: TextStyle(
                              color: _sendAsCollabRequest
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_sendAsCollabRequest) ...[
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCollabRole,
                        isDense: true,
                        dropdownColor: const Color(0xFF161821),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        items: AppState.availableCollabRoles
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCollabRole = val);
                          }
                        },
                      ),
                    ),
                  ],
                  if (_sendAsCollabRequest && refTrack != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '• ${refTrack.title}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      onSubmitted: (_) => _handleSend(partner),
                      decoration: InputDecoration(
                        hintText: _sendAsCollabRequest
                            ? 'İş birliği teklifini yaz...'
                            : 'Mesaj yaz...',
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
                        fillColor: const Color(0xFF070709),
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
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleSend(partner),
                    child: const Text(
                      'Gönder',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
