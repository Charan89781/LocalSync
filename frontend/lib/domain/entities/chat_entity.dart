import 'package:cloud_firestore/cloud_firestore.dart';

class MessageEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
    };
  }

  factory MessageEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageEntity(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: parseDate(map['timestamp']),
      isRead: map['isRead'] ?? false,
      attachmentUrl: map['attachmentUrl'],
    );
  }
}

class ChatRoomEntity {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? roomName;
  final String? roomIcon;
  final bool isGroup;
  final bool isChannel;
  final String? category;
  final String? description;

  ChatRoomEntity({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.roomName,
    this.roomIcon,
    this.isGroup = false,
    this.isChannel = false,
    this.category,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'roomName': roomName,
      'roomIcon': roomIcon,
      'isGroup': isGroup,
      'isChannel': isChannel,
      'category': category,
      'description': description,
    };
  }

  factory ChatRoomEntity.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return ChatRoomEntity(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: parseDate(map['lastMessageTime']),
      roomName: map['roomName'],
      roomIcon: map['roomIcon'],
      isGroup: map['isGroup'] ?? false,
      isChannel: map['isChannel'] ?? false,
      category: map['category'],
      description: map['description'],
    );
  }
}
