import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Stream<List<ChatRoomEntity>> getChatRooms(String userId) {
    return _db.collection('chatRooms').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => ChatRoomEntity.fromMap(doc.data(), doc.id))
          .toList();

      final rooms = list.where((room) => room.participants.contains(userId) || room.isChannel).toList();

      // Sort in memory: most recent first
      rooms.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime(2000);
        final timeB = b.lastMessageTime ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });
      return rooms;
    });
  }

  @override
  Stream<List<MessageEntity>> getMessages(String roomId) {
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => MessageEntity.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> sendMessage(String roomId, MessageEntity message) async {
    final batch = _db.batch();
    final messageRef =
        _db.collection('chatRooms').doc(roomId).collection('messages').doc();

    final Map<String, dynamic> messageData = message.toMap();
    messageData['timestamp'] = FieldValue.serverTimestamp();

    batch.set(messageRef, messageData);
    batch.update(_db.collection('chatRooms').doc(roomId), {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<String> createChatRoom(List<String> participants,
      {String? name, bool isGroup = false}) async {
    final doc = await _db.collection('chatRooms').add({
      'participants': participants,
      'roomName': name,
      'isGroup': isGroup,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
