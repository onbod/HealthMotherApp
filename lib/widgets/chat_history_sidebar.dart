import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatHistorySidebar extends StatelessWidget {
  final bool isOpen;
  final List<ChatHistoryItem> chatHistory;
  final Function(String) onChatSelected;
  final VoidCallback? onStartNewChat;
  final void Function(String)? onDeleteChat;
  final bool isLoading;
  final String? errorMessage;

  const ChatHistorySidebar({
    super.key,
    required this.isOpen,
    required this.chatHistory,
    required this.onChatSelected,
    this.onStartNewChat,
    this.onDeleteChat,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isOpen ? 280 : 0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child:
          isOpen
              ? Column(
                children: [
                  if (onStartNewChat != null)
                    ListTile(
                      leading: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
                      title: const Text(
                        'Start New Chat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: onStartNewChat,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          'Chat History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => onChatSelected(''),
                          color: const Color(0xFF7C4DFF),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildChatList()),
                ],
              )
              : null,
    );
  }

  Widget _buildChatList() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading chat history',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (chatHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No chat history',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new conversation to see it here',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final chat = chatHistory[index];
        return ListTile(
          title: Text(
            chat.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                chat.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(chat.timestamp),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
            child: Text(
              chat.title.isNotEmpty ? chat.title[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing:
              onDeleteChat != null
                  ? IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red[300],
                    onPressed: () => onDeleteChat!(chat.id),
                  )
                  : null,
          onTap: () => onChatSelected(chat.id),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

class ChatHistoryItem {
  final String id;
  final String title;
  final String preview;
  final DateTime timestamp;
  final String? patientName;
  final String? patientIdentifier;

  ChatHistoryItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    this.patientName,
    this.patientIdentifier,
  });
}
