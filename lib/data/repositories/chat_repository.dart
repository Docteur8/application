import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../services/firebase_service.dart';
import '../../core/utils/helpers.dart';

class ChatRepository {
  Future<String> createOrGetChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    required String vehicleId,
    required String vehicleTitle,
    required String vehicleImage,
  }) async {
    try {
      final chatId = Helpers.getChatId(currentUserId, otherUserId);

      final chatDoc = await FirebaseService.chatsCollection.doc(chatId).get();

      if (!chatDoc.exists) {
        final chat = ChatModel(
          id: chatId,
          participants: [currentUserId, otherUserId],
          participantNames: {
            currentUserId: currentUserName,
            otherUserId: otherUserName,
          },
          lastMessage: '',
          lastMessageTime: DateTime.now(),
          vehicleId: vehicleId,
          vehicleTitle: vehicleTitle,
          vehicleImage: vehicleImage,
        );

        await FirebaseService.chatsCollection.doc(chatId).set(chat.toFirestore());
      }

      return chatId;
    } catch (e) {
      throw Exception('Erreur lors de la création du chat: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
  }) async {
    try {
      final messageModel = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await FirebaseService.messagesCollection.add(messageModel.toFirestore());

      await FirebaseService.chatsCollection.doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  Stream<List<ChatModel>> getChatsStream(String userId) {
    return FirebaseService.chatsStream(userId).map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return FirebaseService.messagesStream(chatId).map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final snapshot = await FirebaseService.messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseService.firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseService.messagesCollection
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await FirebaseService.chatsCollection.doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}