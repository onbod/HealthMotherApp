import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../widgets/chat_history_sidebar.dart';

class ChatHistoryService {
  static const _historyKey = 'chat_history';

  Future<void> addMessageToChat(
      String chatId, ChatMessage message, String preview) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyJson);

    if (!history.containsKey(chatId)) {
      history[chatId] = {
        'messages': [],
        'preview': '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    final chat = history[chatId];
    chat['messages'].add(message.toJson());
    chat['preview'] = preview; // Update preview with the latest message
    chat['timestamp'] =
        DateTime.now().toIso8601String(); // Update timestamp on new message

    await prefs.setString(_historyKey, json.encode(history));
  }

  Future<List<ChatMessage>> getMessagesForChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyJson);

    if (history.containsKey(chatId)) {
      final messagesJson = history[chatId]['messages'] as List;
      return messagesJson
          .map((json) => ChatMessage.fromJson(json))
          .toList()
          .cast<ChatMessage>();
    }
    return [];
  }

  Future<List<ChatHistoryItem>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyJson);

    final List<ChatHistoryItem> chatHistory = [];
    history.forEach((chatId, chatData) {
      // Safely access preview
      final preview = chatData['preview'] as String? ?? 'No preview available';

      chatHistory.add(
        ChatHistoryItem(
          id: chatId,
          title: 'Chat from ${DateTime.parse(chatData['timestamp']).toLocal()}',
          preview: preview,
          timestamp: DateTime.parse(chatData['timestamp']),
        ),
      );
    });

    // Sort by most recent
    chatHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return chatHistory;
  }

  Future<void> deleteChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '{}';
    final Map<String, dynamic> history = json.decode(historyJson);
    if (history.containsKey(chatId)) {
      history.remove(chatId);
      await prefs.setString(_historyKey, json.encode(history));
    }
  }
}
