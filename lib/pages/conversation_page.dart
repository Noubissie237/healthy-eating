import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/chat.dart';
import 'package:uuid/uuid.dart';

class ConversationPage extends StatefulWidget {
  final String contactName;
  final String avatarUrl;
  final String conversationId;
  final String currentUserId; // ID de l'utilisateur actuel
  final String receiverId;

  const ConversationPage({
    super.key,
    required this.contactName,
    required this.avatarUrl,
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Message> messages = [];
  bool isLoading = true;
  final int _messagesPerPage = 30;
  int _currentPage = 0;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoading &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  Future<void> _initializeConversation() async {
    try {
      // Vérifier si la conversation existe déjà
      final conversations = await _dbHelper.getConversations();
      final existingConversation = conversations
          .where((conv) => conv.id == widget.conversationId)
          .isEmpty;

      if (existingConversation) {
        // Créer une nouvelle conversation si elle n'existe pas
        final newConversation = Conversation(
          id: widget.conversationId,
          name: widget.contactName,
          avatarUrl: widget.avatarUrl,
          isGroup: false,
          participantIds: [widget.currentUserId],
          createdAt: DateTime.now(),
          lastMessageAt: DateTime.now(),
          lastMessageContent: null,
          lastMessageType: null,
        );
        await _dbHelper.insertConversation(newConversation);
      }
    } catch (e) {
      debugPrint('Erreur lors de l_initialisation de la conversation: $e');
    }
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);
    try {
      final loadedMessages = await _dbHelper.getMessages(
        widget.conversationId,
        limit: _messagesPerPage,
        offset: _currentPage * _messagesPerPage,
      );
      setState(() {
        messages = loadedMessages;
        _hasMoreMessages = loadedMessages.length == _messagesPerPage;
        isLoading = false;
      });
    } catch (e) {
      // Gérer l'erreur
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      _currentPage++;
      final moreMessages = await _dbHelper.getMessages(
        widget.conversationId,
        limit: _messagesPerPage,
        offset: _currentPage * _messagesPerPage,
      );
      setState(() {
        messages.addAll(moreMessages);
        _hasMoreMessages = moreMessages.length == _messagesPerPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage(String content, MessageType type) async {
    if (content.isEmpty) return;

    final newMessage = Message(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      receiverId: widget.receiverId, // À adapter selon votre logique
      type: type,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    try {
      // Insérer d'abord le message
      await _dbHelper.insertMessage(newMessage);

      // Mettre à jour l'UI immédiatement
      setState(() {
        messages.insert(0, newMessage);
        _messageController.clear();
      });

      // Mettre à jour la conversation avec le dernier message
      final updatedConversation = Conversation(
        id: widget.conversationId,
        name: widget.contactName,
        avatarUrl: widget.avatarUrl,
        isGroup: false,
        participantIds: [widget.currentUserId],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        lastMessageContent: content,
        lastMessageType: type,
        lastMessageSender: widget.currentUserId,
        unreadCount: 0,
      );

      // Mettre à jour la conversation
      await _dbHelper.updateConversation(updatedConversation);

      // Mettre à jour le statut du message
      await _dbHelper.updateMessageStatus(newMessage.id, MessageStatus.sent);

      // Mettre à jour l'UI avec le nouveau statut
      setState(() {
        final index = messages.indexWhere((msg) => msg.id == newMessage.id);
        if (index != -1) {
          messages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            senderId: newMessage.senderId,
            receiverId: newMessage.receiverId,
            type: newMessage.type,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            status: MessageStatus.sent,
          );
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de l_envoi du message: $e');
      // Mettre à jour le statut en cas d'échec
      await _dbHelper.updateMessageStatus(newMessage.id, MessageStatus.failed);

      // Mettre à jour l'UI pour montrer l'échec
      setState(() {
        final index = messages.indexWhere((msg) => msg.id == newMessage.id);
        if (index != -1) {
          messages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            senderId: newMessage.senderId,
            receiverId: newMessage.receiverId,
            type: newMessage.type,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            status: MessageStatus.failed,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.avatarUrl),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  reverse: true,
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _MessageBubble(
                      message: messages[index],
                      currentUserId: widget.currentUserId,
                    );
                  },
                ),
                if (isLoading && messages.isEmpty)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 8,
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Implémenter la sélection de fichier
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // Implémenter la capture photo
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Implémenter l'enregistrement vocal
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage(_messageController.text, MessageType.text);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String currentUserId;

  const _MessageBubble({
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isMe ? Colors.blue[100] : const Color.fromRGBO(29, 158, 158, 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.content);
      case MessageType.image:
        return Image.network(
          message.content,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack),
            const SizedBox(width: 8),
            Text('Message audio'), // À remplacer par un lecteur audio
          ],
        );
      default:
        return Text('Type de message non pris en charge');
    }
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color? color;

    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case MessageStatus.sent:
        iconData = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(
      iconData,
      size: 16,
      color: color,
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
