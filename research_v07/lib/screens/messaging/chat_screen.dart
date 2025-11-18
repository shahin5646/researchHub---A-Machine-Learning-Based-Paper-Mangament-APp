import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../services/messaging_service.dart';
import '../../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserUsername;
  final String? otherUserPhotoUrl;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserUsername,
    this.otherUserPhotoUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _isInputFocused = false;
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(_onFocusChanged);
    _markMessagesAsRead();
  }

  void _onMessageChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {
      _isInputFocused = _focusNode.hasFocus;
    });
  }

  Future<void> _markMessagesAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      await _messagingService.markMessagesAsRead(
        widget.conversationId,
        currentUser.uid,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final content = _messageController.text.trim();
      _messageController.clear();

      await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        senderUsername: currentUser.username,
        senderPhotoUrl: currentUser.photoURL,
        content: content,
        recipientId: widget.otherUserId,
      );

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      _messageController.text = _messageController.text;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    _messageController.removeListener(_onMessageChanged);
    _focusNode.removeListener(_onFocusChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Text('Please log in to chat'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFF0F2F5),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Minimal back button
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1F2937),
                        size: 15,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Avatar with thin 1.5px ring
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFF0F7FF),
                        backgroundImage: widget.otherUserPhotoUrl != null
                            ? NetworkImage(widget.otherUserPhotoUrl!)
                            : null,
                        child: widget.otherUserPhotoUrl == null
                            ? Text(
                                widget.otherUserName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A7BD5),
                                  letterSpacing: 0.2,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Clean typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.otherUserUsername != null)
                          Text(
                            '@${widget.otherUserUsername}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFAFBFC),
              Color(0xFFF5F7FA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream:
                    _messagingService.getMessagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glass-like card
                          Container(
                            padding: const EdgeInsets.all(36),
                            margin: const EdgeInsets.symmetric(horizontal: 44),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withOpacity(0.85),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color:
                                      const Color(0xFF3A7BD5).withOpacity(0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Soft gradient icon
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00D2FF)
                                            .withOpacity(0.1),
                                        const Color(0xFF3A7BD5)
                                            .withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [
                                        Color(0xFF00D2FF),
                                        Color(0xFF3A7BD5)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Say Hi 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Start the conversation',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9CA3AF),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Mark messages as read when viewing
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markMessagesAsRead();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 28),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser.uid;
                      final showAvatar = index == 0 ||
                          messages[index - 1].senderId != message.senderId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe && showAvatar)
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00D2FF),
                                      Color(0xFF3A7BD5)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: const Color(0xFFF0F7FF),
                                    backgroundImage: message.senderPhotoUrl !=
                                            null
                                        ? NetworkImage(message.senderPhotoUrl!)
                                        : null,
                                    child: message.senderPhotoUrl == null
                                        ? Text(
                                            message.senderName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3A7BD5),
                                              letterSpacing: 0.15,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              )
                            else if (!isMe)
                              const SizedBox(width: 30),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isMe
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF1ED5FF),
                                                Color(0xFF4F92E8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isMe ? null : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft:
                                            Radius.circular(isMe ? 18 : 4),
                                        bottomRight:
                                            Radius.circular(isMe ? 4 : 18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isMe
                                              ? const Color(0xFF3A7BD5)
                                                  .withOpacity(0.15)
                                              : Colors.black.withOpacity(0.035),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Text(
                                      timeago.format(message.timestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFB4BBC6),
                                        letterSpacing: 0.1,
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
                },
              ),
            ),
            // Sleek input bar with minimal design
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFF0F2F5),
                    width: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isInputFocused
                                ? const Color(0xFF00D2FF).withOpacity(0.25)
                                : const Color(0xFFE9ECEF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isInputFocused
                                  ? const Color(0xFF00D2FF).withOpacity(0.06)
                                  : Colors.black.withOpacity(0.015),
                              blurRadius: _isInputFocused ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(
                              color: Color(0xFFB4BBC6),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                            letterSpacing: 0.1,
                            height: 1.5,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Minimal send button
                    GestureDetector(
                      onTapDown: (_) {
                        if (_messageController.text.trim().isNotEmpty &&
                            !_isSending) {
                          _sendButtonController.forward();
                        }
                      },
                      onTapUp: (_) {
                        _sendButtonController.reverse();
                        _sendMessage();
                      },
                      onTapCancel: () {
                        _sendButtonController.reverse();
                      },
                      child: AnimatedBuilder(
                        animation: _sendButtonController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 - (_sendButtonController.value * 0.08),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient:
                                    _messageController.text.trim().isEmpty ||
                                            _isSending
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFF1ED5FF),
                                              Color(0xFF4F92E8)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                color: _messageController.text.trim().isEmpty ||
                                        _isSending
                                    ? const Color(0xFFE9ECEF)
                                    : null,
                                shape: BoxShape.circle,
                                boxShadow:
                                    _messageController.text.trim().isEmpty ||
                                            _isSending
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: const Color(0xFF3A7BD5)
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                              ),
                              child: Center(
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFADB5BD)),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color: _messageController.text
                                                .trim()
                                                .isEmpty
                                            ? const Color(0xFFB4BBC6)
                                            : Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
