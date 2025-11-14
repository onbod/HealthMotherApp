import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_sidebar.dart';
import '../widgets/shared_app_bar.dart';

class FirstAidAssistanceScreen extends StatefulWidget {
  const FirstAidAssistanceScreen({super.key});

  @override
  State<FirstAidAssistanceScreen> createState() =>
      _FirstAidAssistanceScreenState();
}

class _FirstAidAssistanceScreenState extends State<FirstAidAssistanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();

  List<ChatMessage> _messages = [];
  List<ChatHistoryItem> _chatHistory = [];
  String? _currentChatId;
  bool _isLoading = false;
  bool _isSidebarOpen = false;

  final Color primaryColor = const Color(0xFF7C4DFF);
  final Uuid _uuid = const Uuid();
  static const String _lastChatIdKey = 'last_opened_chat_id';

  @override
  void initState() {
    super.initState();
    _restoreLastChat();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final history = await _chatHistoryService.getChatHistory();
    setState(() {
      _chatHistory = history;
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUserMessage: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isLoading = true;
      _messages.insert(0, userMessage);
      _messages.insert(
        0,
        ChatMessage(
          id: _uuid.v4(),
          text: 'MamaBot is typing...',
          isUserMessage: false,
          timestamp: DateTime.now(),
          isTyping: true,
          animate: false,
        ),
      );
    });
    _messageController.clear();

    _currentChatId ??= _uuid.v4();

    await _saveMessage(userMessage);

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'chatWithOpenRouter',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'message': text,
      });
      String botResponse;
      if (result.data['error'] != null &&
          result.data['error']['message'] != null) {
        botResponse = result.data['error']['message'];
      } else {
        botResponse = result.data['response'] as String;
      }
      final botMessage = ChatMessage(
        id: _uuid.v4(),
        text: botResponse,
        isUserMessage: false,
        timestamp: DateTime.now(),
        animate: true,
      );
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.insert(0, botMessage);
      });
      await _saveMessage(botMessage);
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
      });
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text:
            'Sorry, I encountered an error: ${e.message}. Please try again later.',
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
      await _saveMessage(errorMessage);
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
      });
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        text: 'An unexpected error occurred. Please try again.',
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
      await _saveMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
      _loadChatHistory(); // Refresh history
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    if (_currentChatId != null) {
      await _chatHistoryService.addMessageToChat(
        _currentChatId!,
        message,
        _messages.first.text,
      );
    }
  }

  Future<void> _restoreLastChat() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChatId = prefs.getString(_lastChatIdKey);
    if (lastChatId != null) {
      final chatMessages = await _chatHistoryService.getMessagesForChat(
        lastChatId,
      );
      if (chatMessages.isNotEmpty) {
        // Sort messages newest to oldest
        chatMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        setState(() {
          _currentChatId = lastChatId;
          _messages = chatMessages;
        });
      }
    }
  }

  void _onChatSelected(String chatId) async {
    if (chatId.isEmpty) {
      // Close sidebar or create new chat
      setState(() {
        _isSidebarOpen = false;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastChatIdKey, chatId);
    final chatMessages = await _chatHistoryService.getMessagesForChat(chatId);
    // Sort messages newest to oldest
    chatMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _currentChatId = chatId;
      _messages = chatMessages;
      _isSidebarOpen = false;
    });
  }

  void _startNewChat() async {
    setState(() {
      _currentChatId = null;
      _messages = [];
      _isSidebarOpen = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastChatIdKey);
  }

  void _deleteChat(String chatId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text(
              'Are you sure you want to delete this chat history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    await _chatHistoryService.deleteChat(chatId);
    final prefs = await SharedPreferences.getInstance();
    final lastChatId = prefs.getString(_lastChatIdKey);
    if (_currentChatId == chatId) {
      setState(() {
        _currentChatId = null;
        _messages = [];
      });
      if (lastChatId == chatId) {
        await prefs.remove(_lastChatIdKey);
      }
    }
    _loadChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: SharedAppBar(
        visitNumber: '', // Not used in this layout
        screenTitle: null,
        onSidebarToggle: () {
          setState(() {
            _isSidebarOpen = !_isSidebarOpen;
          });
        },
        isSidebarOpen: _isSidebarOpen,
        // The notification icon can be added back if needed
        // onNotificationPressed: () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => const NotificationsScreen(),
        //     ),
        //   );
        // },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    _messages.isEmpty
                        ? _buildWelcomeMessage()
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          reverse: true,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return ChatMessageWidget(
                              message: message,
                              onTypewriterComplete: () {
                                setState(() {
                                  message.animate = false;
                                });
                              },
                            );
                          },
                        ),
              ),
              const Divider(height: 1.0),
              SafeArea(
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                ),
              ),
            ],
          ),
          ChatHistorySidebar(
            isOpen: _isSidebarOpen,
            chatHistory: _chatHistory,
            onChatSelected: _onChatSelected,
            onStartNewChat: _startNewChat,
            onDeleteChat: _deleteChat,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Hello! I\'m MamaBot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your AI assistant for first aid during pregnancy. How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
              enabled: !_isLoading,
            ),
          ),
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    )
                    : Icon(Icons.send_rounded, color: primaryColor),
            onPressed:
                _isLoading
                    ? null
                    : () => _handleSubmitted(_messageController.text),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final void Function()? onTypewriterComplete;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onTypewriterComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUserMessage;
    if (message.isTyping) {
      return _TypingIndicatorBubble(isUser: false);
    }
    if (!isUser && message.animate) {
      return _TypewriterBubble(
        text: message.text,
        onComplete: onTypewriterComplete,
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF7C4DFF) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0),
                  bottomLeft:
                      isUser
                          ? const Radius.circular(20.0)
                          : const Radius.circular(0),
                  bottomRight:
                      isUser
                          ? const Radius.circular(0)
                          : const Radius.circular(20.0),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  final bool isUser;
  const _TypingIndicatorBubble({super.key, required this.isUser});

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: AnimatedBuilder(
                animation: _dotCount,
                builder: (context, child) {
                  String dots = '.' * _dotCount.value;
                  return Text(
                    'MamaBot is typing$dots',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypewriterBubble extends StatefulWidget {
  final String text;
  final VoidCallback? onComplete;
  const _TypewriterBubble({super.key, required this.text, this.onComplete});

  @override
  State<_TypewriterBubble> createState() => _TypewriterBubbleState();
}

class _TypewriterBubbleState extends State<_TypewriterBubble> {
  String _displayed = '';
  int _index = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _showNextChar();
  }

  void _showNextChar() async {
    if (_index < widget.text.length) {
      await Future.delayed(const Duration(milliseconds: 18));
      setState(() {
        _displayed += widget.text[_index];
        _index++;
      });
      _showNextChar();
    } else if (!_completed) {
      _completed = true;
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Text(
                _displayed,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
