import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../widgets/chat_history_sidebar.dart';
import '../core/config.dart';
import 'local_chat_storage.dart';
import 'dart:io';

class ChatHistoryService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> _getJwt() async {
    return await _secureStorage.read(key: 'jwt');
  }

  Uri _api(String path) => Uri.parse(AppConfig.getApiUrl(path));

  // Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Create/send a message via backend and rely on server to manage threads
  Future<ChatMessage> addMessageToChat(
      String chatId, ChatMessage message, String preview) async {
    // Save message locally first (optimistic update)
    // Use negative ID for local-only messages (will be replaced by server ID)
    final localMessage = message.copyWith(
      id: -DateTime.now().millisecondsSinceEpoch, // Temporary local ID (negative to avoid conflicts)
      createdAt: DateTime.now(),
    );
    await LocalChatStorage.addMessage(chatId, localMessage);

    // Try to send to backend
    final isOnline = await _isOnline();
    if (!isOnline) {
      // Save as pending message for later sync
      await LocalChatStorage.savePendingMessage(chatId, localMessage);
      return localMessage;
    }

    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        // If no JWT, save as pending
        await LocalChatStorage.savePendingMessage(chatId, localMessage);
        return localMessage;
      }

      final response = await http.post(
        _api('/chat/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'sender_id': message.senderId.isNotEmpty ? message.senderId : chatId,
          'receiver_id': message.receiverId.isNotEmpty ? message.receiverId : 'health_worker',
          'message': message.message,
          'fhir_resource': message.fhirResource,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final serverMessage = ChatMessage.fromJson(jsonMap);
        
        // Replace local message with server message
        final localMessages = await LocalChatStorage.loadMessages(chatId);
        localMessages.removeWhere((m) => m.id == localMessage.id);
        localMessages.add(serverMessage);
        await LocalChatStorage.saveMessages(chatId, localMessages);
        
        return serverMessage;
      } else {
        // Save as pending if server error
        await LocalChatStorage.savePendingMessage(chatId, localMessage);
        return localMessage;
      }
    } catch (e) {
      // Network error - message already saved locally and as pending
      print('Error sending message to server: $e');
      await LocalChatStorage.savePendingMessage(chatId, localMessage);
      return localMessage;
    }
  }

  // Load messages for a chatId (patient identifier/phone) from backend
  // Falls back to local storage if offline or backend fails
  Future<List<ChatMessage>> getMessagesForChat(String chatId) async {
    // Always load from local storage first for instant display
    final localMessages = await LocalChatStorage.loadMessages(chatId);
    
    // Try to sync with backend if online
    final isOnline = await _isOnline();
    if (!isOnline) {
      return localMessages;
    }

    try {
      final jwt = await _getJwt();
      if (jwt == null) {
        return localMessages; // Return local messages if no JWT
      }

      final response = await http.get(
        _api('/chat/$chatId/messages'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body) as List<dynamic>;
        final serverMessages = list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        
        // Merge local and server messages, removing duplicates
        final mergedMessages = <ChatMessage>[];
        final serverMessageIds = serverMessages.map((m) => m.id).toSet();
        
        // Add server messages
        mergedMessages.addAll(serverMessages);
        
        // Add local messages that aren't on server (pending messages)
        for (final localMsg in localMessages) {
          if (!serverMessageIds.contains(localMsg.id)) {
            mergedMessages.add(localMsg);
          }
        }
        
        // Sort by timestamp
        mergedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Save merged messages locally
        await LocalChatStorage.saveMessages(chatId, mergedMessages);
        
        // Try to sync pending messages
        await _syncPendingMessages(chatId);
        
        return mergedMessages;
      } else {
        // Return local messages if server error
        return localMessages;
      }
    } catch (e) {
      print('Error fetching messages from server: $e');
      // Return local messages on error
      return localMessages;
    }
  }

  // Sync pending messages to server
  Future<void> _syncPendingMessages(String chatId) async {
    try {
      final pending = await LocalChatStorage.getPendingMessages();
      final chatPending = pending.where((p) => p['chatId'] == chatId).toList();
      
      if (chatPending.isEmpty) return;
      
      final jwt = await _getJwt();
      if (jwt == null) return;
      
      for (int i = 0; i < chatPending.length; i++) {
        final pendingData = chatPending[i];
        final message = ChatMessage.fromJson(pendingData['message'] as Map<String, dynamic>);
        
        try {
          final response = await http.post(
            _api('/chat/$chatId/messages'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'sender_id': message.senderId.isNotEmpty ? message.senderId : chatId,
              'receiver_id': message.receiverId.isNotEmpty ? message.receiverId : 'health_worker',
              'message': message.message,
              'fhir_resource': message.fhirResource,
            }),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 201) {
            // Remove from pending list
            final allPending = await LocalChatStorage.getPendingMessages();
            final index = allPending.indexWhere((p) => 
              p['chatId'] == chatId && 
              p['timestamp'] == pendingData['timestamp']
            );
            if (index >= 0) {
              await LocalChatStorage.removePendingMessage(index);
            }
            
            // Update local message with server response
            final Map<String, dynamic> jsonMap = json.decode(response.body);
            final serverMessage = ChatMessage.fromJson(jsonMap);
            final localMessages = await LocalChatStorage.loadMessages(chatId);
            localMessages.removeWhere((m) => m.id == message.id);
            localMessages.add(serverMessage);
            await LocalChatStorage.saveMessages(chatId, localMessages);
          }
        } catch (e) {
          print('Error syncing pending message: $e');
          // Continue with next message
        }
      }
    } catch (e) {
      print('Error in syncPendingMessages: $e');
    }
  }

  // Load chat threads history from backend
  Future<List<ChatHistoryItem>> getChatHistory() async {
    final jwt = await _getJwt();
    if (jwt == null) {
      throw StateError('Missing JWT token');
    }
    final response = await http.get(
      _api('/chat_threads'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );
    if (response.statusCode != 200) {
      throw StateError('Failed to load chat history: ${response.statusCode} ${response.body}');
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> rows = (data['data'] as List?) ?? data['rows'] as List? ?? [];

    final items = rows.map((row) {
      final m = row as Map<String, dynamic>;
      final id = (m['id'] ?? m['fhir_id'] ?? '').toString();
      final lastMessage = (m['last_message'] ?? '').toString();
      final patientName = (m['patient_name'] ?? '').toString();
      final patientIdentifier = (m['patient_identifier'] ?? m['user_id'] ?? '').toString();
      final tsString = (m['last_message_time'] ?? m['updated_at'] ?? m['created_at'])?.toString();
      final ts = tsString != null ? DateTime.tryParse(tsString) ?? DateTime.now() : DateTime.now();
      
      // Create a better title using patient name or identifier
      String title;
      if (patientName.isNotEmpty) {
        title = patientName;
      } else if (patientIdentifier.isNotEmpty) {
        title = 'Chat: $patientIdentifier';
      } else {
        title = 'Chat Thread #$id';
      }
      
      return ChatHistoryItem(
        id: id,
        title: title,
        preview: lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
        timestamp: ts,
        patientName: patientName.isNotEmpty ? patientName : null,
        patientIdentifier: patientIdentifier.isNotEmpty ? patientIdentifier : null,
      );
    }).toList();

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  // Optional: implement delete if/when backend supports it
  Future<void> deleteChat(String chatId) async {
    throw UnimplementedError('Deleting chats is not supported by the backend yet.');
  }
}
