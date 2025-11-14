import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/user_session_provider.dart';
import '../services/chat_history_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _chatService = ChatHistoryService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _sending = false;
  String? _currentChatId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _fetchMessages(); // Initial load
    
    // Start polling timer - check for new messages every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final userSession = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );
        final chatId = userSession.clientNumber;
        
        if (chatId != null && chatId == _currentChatId) {
          // Only poll if we're still on the same chat
          _fetchMessages(silent: true); // Silent fetch (no loading indicator)
        }
      } catch (e) {
        print('Error polling for messages: $e');
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final userSession = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      final chatId = userSession.clientNumber;
      
      if (chatId == null) {
        if (!silent) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to view messages')),
            );
          }
        }
        return;
      }
      
      // Update current chat ID
      _currentChatId = chatId;
      
      // Use ChatHistoryService which handles offline/online automatically
      final messages = await _chatService.getMessagesForChat(chatId);
      
      // Check if we have new messages (compare count or last message ID)
      final hasNewMessages = _messages.length != messages.length ||
          (_messages.isNotEmpty && messages.isNotEmpty &&
           (_messages.last['id']?.toString() != messages.last.id?.toString()));
      
      if (mounted) {
        setState(() {
          // Convert ChatMessage objects to maps, ensuring timestamp and status are included
          _messages = messages.map((msg) {
            final json = msg.toJson();
            // Ensure timestamp field exists for UI compatibility
            if (!json.containsKey('timestamp')) {
              json['timestamp'] = msg.timestamp.toIso8601String();
            }
            // Ensure status field exists for UI compatibility
            if (!json.containsKey('status')) {
              json['status'] = msg.isRead ? 'read' : 'sent';
            }
            return json;
          }).toList();
          if (!silent) {
            _isLoading = false;
          }
        });
        
        // Auto-scroll to bottom if new messages arrived
        if (hasNewMessages) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading messages: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      print('Error fetching messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    
    setState(() {
      _sending = true;
    });
    
    try {
      final userSession = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      final chatId = userSession.clientNumber;
      final senderId = userSession.clientNumber;
      
      if (chatId == null || senderId == null) {
        setState(() {
          _sending = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to send messages')),
          );
        }
        return;
      }
      
      // Create message object
      final message = ChatMessage(
        senderId: senderId,
        receiverId: 'health_worker',
        message: text,
        fhirResource: {
          'resourceType': 'Communication',
          'status': 'completed',
          'category': {
            'coding': [
              {
                'system': 'http://who.int/dak/anc',
                'code': 'patient-communication',
                'display': 'Patient Communication',
              },
            ],
          },
          'subject': {'reference': 'Patient/$senderId'},
        },
      );
      
      // Use ChatHistoryService which handles offline/online automatically
      await _chatService.addMessageToChat(chatId, message, text);
      
      setState(() {
        _sending = false;
      });
      
      _messageController.clear();
      // Refresh messages immediately to show the new message (silent to avoid loading indicator)
      await _fetchMessages(silent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() {
        _sending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalNavigation(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: SharedAppBar(visitNumber: 'Chat', isHomeScreen: false),
        body: Column(
          children: [
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? Center(child: Text('No messages yet'))
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isCurrentUser =
                              msg['sender_id'] ==
                              Provider.of<UserSessionProvider>(
                                context,
                                listen: false,
                              ).clientNumber;
                          return _buildMessageBubble(
                            text: msg['message'] ?? msg['text'] ?? '',
                            timestamp: msg['timestamp'] ?? msg['created_at'] ?? msg['last_updated'],
                            isCurrentUser: isCurrentUser,
                            status: msg['status'] ?? (msg['is_read'] == true ? 'read' : 'sent'),
                          );
                        },
                      ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required dynamic timestamp,
    required bool isCurrentUser,
    required String status,
  }) {
    final primaryColor = const Color(0xFF7C4DFF);
    DateTime messageTime;
    if (timestamp is String) {
      messageTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      messageTime = timestamp;
    } else {
      messageTime = DateTime.now();
    }
    final now = DateTime.now();
    String timeText;
    if (now.difference(messageTime).inDays > 0) {
      timeText =
          '${messageTime.day}/${messageTime.month} ${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else {
      timeText =
          '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isCurrentUser ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status == 'read' ? Icons.done_all : Icons.done,
                              size: 12,
                              color:
                                  status == 'read'
                                      ? Colors.blue[200]
                                      : Colors.white70,
                            ),
                            if (status == 'read') ...[
                              const SizedBox(width: 2),
                              Text(
                                'seen',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[200],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final primaryColor = const Color(0xFF7C4DFF);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
