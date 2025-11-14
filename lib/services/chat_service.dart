import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new chat between user and health worker
  Future<String> createChat(String userId, String healthWorkerId) async {
    final chatId = '${userId}_$healthWorkerId';

    // Create the chat document
    await _firestore.collection('chats').doc(chatId).set({
      'userId': userId,
      'healthWorkerId': healthWorkerId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return chatId;
  }

  // Get all chats for a user
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get all chats for a health worker
  Stream<QuerySnapshot> getHealthWorkerChats(String healthWorkerId) {
    return _firestore
        .collection('chats')
        .where('healthWorkerId', isEqualTo: healthWorkerId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Update last message in chat
  Future<void> updateLastMessage(String chatId, String message) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messagesQuery =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('status', isEqualTo: 'sent')
              .get();

      if (messagesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in messagesQuery.docs) {
          batch.update(doc.reference, {'status': 'read'});
        }
        await batch.commit();
      }
    } catch (e) {
      // Ignore permission errors for marking messages as read
      // This is not critical for the chat functionality
      print('Could not mark messages as read: $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if user is authenticated
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Get user role (simplified - in real app this would come from user profile)
  String getUserRole() {
    // For demo purposes, assume current user is always the pregnant mother
    return 'user';
  }
}
