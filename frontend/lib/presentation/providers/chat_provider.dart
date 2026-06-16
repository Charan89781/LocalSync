import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_entity.dart';
import 'auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});

final chatRoomsProvider = StreamProvider<List<ChatRoomEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).getChatRooms(user.id);
});

final messagesProvider =
    StreamProvider.family<List<MessageEntity>, String>((ref, roomId) {
  return ref.watch(chatRepositoryProvider).getMessages(roomId);
});
