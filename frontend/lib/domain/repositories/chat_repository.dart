import '../entities/chat_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatRoomEntity>> getChatRooms(String userId);
  Stream<List<MessageEntity>> getMessages(String roomId);
  Future<void> sendMessage(String roomId, MessageEntity message);
  Future<String> createChatRoom(List<String> participants, {String? name, bool isGroup = false});
}
