// F4 Messages: the list of the user's chats, newest first. It uses a
// Firestore stream, so a new message moves its chat to the top right away.

import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../utils/format.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../widgets/async_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_page.dart';
import 'chat_screen.dart';

/// Inbox tab for farmers and buyers.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _myId = AuthService.currentUser!.id;
  late Stream<List<Chat>> _chats;

  @override
  void initState() {
    super.initState();
    _chats = MessageService().watchChats(_myId);
  }

  /// Starts listening again after an error (the Try again button).
  void _retry() {
    setState(() => _chats = MessageService().watchChats(_myId));
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer = AuthService.currentUser!.isFarmer;
    return TabPage(
      header: PageHeader(
        eyebrow: 'Inbox',
        title: 'Messages',
        lead: isFarmer
            ? 'Chats with buyers about your crops.'
            : 'Chats with farmers about their crops.',
      ),
      child: StreamBuilder<List<Chat>>(
        stream: _chats,
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];
          return AsyncStateView(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            errorMessage: snapshot.hasError ? AppStrings.networkError : null,
            onRetry: _retry,
            isEmpty: chats.isEmpty,
            emptyMessage: isFarmer
                ? 'No messages yet.\nBuyers who message you show up here.'
                : 'No messages yet.\nOpen a crop in the Market and tap '
                      '"Message farmer".',
            // All chats in one white box with lines between them.
            builder: (context) => ListView(
              padding: TabPage.listPadding,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < chats.length; i++) ...[
                        if (i > 0) const Divider(),
                        _buildRow(chats[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One chat: avatar, name, last message and date.
  Widget _buildRow(Chat chat) {
    final otherName = chat.otherUserName(_myId);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          otherName[0].toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      title: Text(
        otherName,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      trailing: Text(formatDate(chat.lastMessageAt), style: AppTextStyles.meta),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chat.id, otherName: otherName),
        ),
      ),
    );
  }
}
