import 'package:flutter/foundation.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  void loadChats(String userId) {
    _chatRepository.getChatsStream(userId).listen((chats) {
      _chats = chats;
      notifyListeners();
    });
  }

  void loadMessages(String chatId) {
    _chatRepository.getMessagesStream(chatId).listen((messages) {
      _messages = messages;
      notifyListeners();
    });
  }

  Future<String?> createOrGetChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    required String vehicleId,
    required String vehicleTitle,
    required String vehicleImage,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final chatId = await _chatRepository.createOrGetChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserName: currentUserName,
        otherUserName: otherUserName,
        vehicleId: vehicleId,
        vehicleTitle: vehicleTitle,
        vehicleImage: vehicleImage,
      );

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatRepository.markMessagesAsRead(chatId, userId);
      await loadUnreadCount(userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> loadUnreadCount(String userId) async {
    try {
      _unreadCount = await _chatRepository.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}