import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class LocalChatStorage {
  static const String _messagesPrefix = 'chat_messages_';
  static const String _pendingMessagesKey = 'chat_pending_messages';
  static const String _lastSyncKey = 'chat_last_sync_';

  // Save messages for a chat locally
  static Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((msg) => jsonEncode(msg.toJson())).toList();
      await prefs.setStringList('$_messagesPrefix$chatId', messagesJson);
      await prefs.setString('$_lastSyncKey$chatId', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving messages locally: $e');
    }
  }

  // Load messages for a chat from local storage
  static Future<List<ChatMessage>> loadMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('$_messagesPrefix$chatId');
      if (messagesJson == null || messagesJson.isEmpty) {
        return [];
      }
      return messagesJson
          .map((jsonStr) => ChatMessage.fromJson(json.decode(jsonStr) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading messages locally: $e');
      return [];
    }
  }

  // Add a single message to local storage
  static Future<void> addMessage(String chatId, ChatMessage message) async {
    try {
      final messages = await loadMessages(chatId);
      messages.add(message);
      await saveMessages(chatId, messages);
    } catch (e) {
      print('Error adding message locally: $e');
    }
  }

  // Save a pending message (sent while offline)
  static Future<void> savePendingMessage(String chatId, ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingMessagesKey) ?? [];
      final messageData = {
        'chatId': chatId,
        'message': message.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      pendingJson.add(jsonEncode(messageData));
      await prefs.setStringList(_pendingMessagesKey, pendingJson);
    } catch (e) {
      print('Error saving pending message: $e');
    }
  }

  // Get all pending messages
  static Future<List<Map<String, dynamic>>> getPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingMessagesKey) ?? [];
      return pendingJson
          .map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error loading pending messages: $e');
      return [];
    }
  }

  // Remove a pending message after successful sync
  static Future<void> removePendingMessage(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList(_pendingMessagesKey) ?? [];
      if (index >= 0 && index < pendingJson.length) {
        pendingJson.removeAt(index);
        await prefs.setStringList(_pendingMessagesKey, pendingJson);
      }
    } catch (e) {
      print('Error removing pending message: $e');
    }
  }

  // Clear all pending messages
  static Future<void> clearPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingMessagesKey);
    } catch (e) {
      print('Error clearing pending messages: $e');
    }
  }

  // Get last sync time for a chat
  static Future<DateTime?> getLastSync(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncStr = prefs.getString('$_lastSyncKey$chatId');
      if (syncStr != null) {
        return DateTime.tryParse(syncStr);
      }
    } catch (e) {
      print('Error getting last sync: $e');
    }
    return null;
  }

  // Clear all messages for a chat
  static Future<void> clearMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_messagesPrefix$chatId');
      await prefs.remove('$_lastSyncKey$chatId');
    } catch (e) {
      print('Error clearing messages: $e');
    }
  }

  // Get all chat IDs that have local messages
  static Future<List<String>> getAllChatIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      return allKeys
          .where((key) => key.startsWith(_messagesPrefix))
          .map((key) => key.substring(_messagesPrefix.length))
          .toList();
    } catch (e) {
      print('Error getting all chat IDs: $e');
      return [];
    }
  }
}



