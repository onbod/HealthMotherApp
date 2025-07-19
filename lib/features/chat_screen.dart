import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/user_session_provider.dart';
import '../core/config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<String?> _getJwt() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt');
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    final chatId = userSession.clientNumber;
    final jwt = await _getJwt();
    if (chatId == null || jwt == null) return;
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/chat/$chatId/messages')),
      headers: {'Authorization': 'Bearer $jwt'},
    );
    if (response.statusCode == 200) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load messages')));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    final chatId = userSession.clientNumber;
    final senderId = userSession.clientNumber;
    final receiverId = 'health_worker'; // or use actual health worker id
    final jwt = await _getJwt();
    if (chatId == null || senderId == null || jwt == null) return;
    final response = await http.post(
      Uri.parse(AppConfig.getApiUrl('/chat/$chatId/messages')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': text,
        'who_guideline': 'Respectful communication',
        'dak_guideline': 'Digital Adherence',
        'fhir_resource': null,
      }),
    );
    setState(() {
      _sending = false;
    });
    if (response.statusCode == 201) {
      _messageController.clear();
      await _fetchMessages();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message')));
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
                            text: msg['message'] ?? '',
                            timestamp: msg['timestamp'],
                            isCurrentUser: isCurrentUser,
                            status: msg['status'] ?? 'sent',
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
