import 'package:flutter/material.dart';

class ChatHistorySidebar extends StatelessWidget {
  final bool isOpen;
  final List<ChatHistoryItem> chatHistory;
  final Function(String) onChatSelected;
  final VoidCallback? onStartNewChat;
  final void Function(String)? onDeleteChat;

  const ChatHistorySidebar({
    Key? key,
    required this.isOpen,
    required this.chatHistory,
    required this.onChatSelected,
    this.onStartNewChat,
    this.onDeleteChat,
  }) : super(key: key);

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
      child: isOpen
          ? Column(
              children: [
                if (onStartNewChat != null)
                  ListTile(
                    leading: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
                    title: const Text('Start New Chat',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                Expanded(
                  child: ListView.builder(
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      return ListTile(
                        title: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          chat.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF7C4DFF,
                          ).withOpacity(0.1),
                          child: Text(
                            chat.title[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF7C4DFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        trailing: onDeleteChat != null
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => onDeleteChat!(chat.id),
                              )
                            : null,
                        onTap: () => onChatSelected(chat.id),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class ChatHistoryItem {
  final String id;
  final String title;
  final String preview;
  final DateTime timestamp;

  ChatHistoryItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
  });
}
