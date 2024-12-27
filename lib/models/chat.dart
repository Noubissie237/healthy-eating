import 'dart:convert';

enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  location,
  voice,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? receiverId;
  final MessageType type;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? replyToMessageId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    required this.type,
    required this.content,
    this.metadata,
    required this.timestamp,
    required this.status,
    this.isDeleted = false,
    this.deletedAt,
    this.replyToMessageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type.toString(),
      'content': content,
      'metadata': metadata != null ? json.encode(metadata) : null,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'reply_to_message_id': replyToMessageId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      content: map['content'],
      metadata: map['metadata'] != null ? json.decode(map['metadata']) : null,
      timestamp: DateTime.parse(map['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      isDeleted: map['is_deleted'] == 1,
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
      replyToMessageId: map['reply_to_message_id'],
    );
  }
}

// conversation_model.dart
class Conversation {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isGroup;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessageContent;
  final MessageType? lastMessageType;
  final bool isPinned;
  final bool isMuted;
  // Ajout des nouvelles propriétés
  final int unreadCount;
  final String? lastMessageSender;

  Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isGroup,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageType,
    this.isPinned = false,
    this.isMuted = false,
    // Initialisation des nouvelles propriétés
    this.unreadCount = 0,
    this.lastMessageSender,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_group': isGroup ? 1 : 0,
      'participant_ids': json.encode(participantIds),
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message_content': lastMessageContent,
      'last_message_type': lastMessageType?.toString(),
      'is_pinned': isPinned ? 1 : 0,
      'is_muted': isMuted ? 1 : 0,
      // Ajout des nouveaux champs dans le map
      'unread_count': unreadCount,
      'last_message_sender': lastMessageSender,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      name: map['name'],
      avatarUrl: map['avatar_url'],
      isGroup: map['is_group'] == 1,
      participantIds: List<String>.from(json.decode(map['participant_ids'])),
      createdAt: DateTime.parse(map['created_at']),
      lastMessageAt: DateTime.parse(map['last_message_at']),
      lastMessageContent: map['last_message_content'],
      lastMessageType: map['last_message_type'] != null
          ? MessageType.values.firstWhere(
              (e) => e.toString() == map['last_message_type'],
            )
          : null,
      isPinned: map['is_pinned'] == 1,
      isMuted: map['is_muted'] == 1,
      // Récupération des nouveaux champs depuis le map
      unreadCount: map['unread_count'] ?? 0,
      lastMessageSender: map['last_message_sender'],
    );
  }
}
