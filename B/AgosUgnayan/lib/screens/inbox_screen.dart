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
    return Scaffold(
      appBar: AppBar(title: const Text('MESSAGES')),
      body: StreamBuilder<List<Chat>>(
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
            builder: (context) => ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherName = chat.otherUserName(_myId);
                return ListTile(
                  tileColor: AppColors.surface,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(otherName[0].toUpperCase()),
                  ),
                  title: Text(otherName),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    formatDate(chat.lastMessageAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(chatId: chat.id, otherName: otherName),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
