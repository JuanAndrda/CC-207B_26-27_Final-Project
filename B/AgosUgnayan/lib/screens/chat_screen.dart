// F4 Messages: one conversation. Messages arrive live through a Firestore
// stream; the newest is at the bottom, like any chat app.

import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../utils/app_exception.dart';
import '../utils/format.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';

/// The chat with [otherName]. [draft] is pre-typed text the user can send.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.draft = '',
  });

  final String chatId;
  final String otherName;
  final String draft;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = MessageService();
  final _myId = AuthService.currentUser!.id;
  late final _textController = TextEditingController(text: widget.draft);
  late Stream<List<ChatMessage>> _messages;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = _service.watchMessages(widget.chatId);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (text.length > 1000) {
      showError(context, AppStrings.tooLong(1000));
      return;
    }
    setState(() => _isSending = true);
    try {
      await _service.send(chatId: widget.chatId, senderId: _myId, text: text);
      _textController.clear();
    } catch (e) {
      if (mounted) showError(context, friendlyMessage(e));
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName.toUpperCase())),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return AsyncStateView(
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  errorMessage: snapshot.hasError
                      ? AppStrings.networkError
                      : null,
                  onRetry: () => setState(
                    () => _messages = _service.watchMessages(widget.chatId),
                  ),
                  isEmpty: messages.isEmpty,
                  emptyMessage: 'Say hello to ${widget.otherName}!',
                  // reverse: true puts item 0 (the newest) at the bottom.
                  builder: (context) => ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSizes.small),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _buildBubble(messages[index]),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  /// One message: mine on the right in green, theirs on the left in white.
  Widget _buildBubble(ChatMessage message) {
    final isMine = message.senderId == _myId;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMine ? Colors.white : AppColors.text),
            ),
            Text(
              formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isMine ? AppColors.onPrimaryMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSizes.small),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: 'Type a message'),
              ),
            ),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: _isSending ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
