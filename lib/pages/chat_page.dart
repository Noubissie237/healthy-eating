import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/chat.dart';
import 'package:food_app/pages/conversation_page.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Conversation> _conversations = [];
  List<Users> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _dbHelper.getConversations(),
        _dbHelper.getUsers(),
      ]);

      print("Conversations chargées: ${results[0]}");
      print("Utilisateurs chargés: ${results[1]}");

      setState(() {
        _conversations = results[0] as List<Conversation>;
        _users = results[1] as List<Users>;
        _isLoading = false;
      });

      // Vérification après chargement
      print("Nombre de conversations: ${_conversations.length}");
      print("Nombre d'utilisateurs: ${_users.length}");
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur lors du chargement des données: $e');
    }
  }

  Users? _findUserForConversation(Conversation conversation) {
    print("Début _findUserForConversation");
    print("Est-ce un groupe ? ${conversation.isGroup}");
    print("Participants IDs: ${conversation.participantIds}");
    print("Current user ID: ${widget.currentUserId}");

    if (conversation.isGroup) return null;
    if (conversation.participantIds.isEmpty) {
      print("Liste des participants vide");
      return null;
    }

    String? otherUserId;
    try {
      otherUserId = conversation.participantIds
          .firstWhere((id) => id != widget.currentUserId);
      print("ID de l'autre participant trouvé: $otherUserId");
    } catch (e) {
      print('Aucun autre participant trouvé dans la conversation: $e');
      return null;
    }

    print(
        "Liste des utilisateurs disponibles: ${_users.map((u) => '${u.id}: ${u.fullname}').join(', ')}");

    try {
      final user = _users.firstWhere((user) => user.id == otherUserId);
      print("Utilisateur trouvé: ${user.fullname}");
      return user;
    } catch (e) {
      print('Utilisateur non trouvé pour l\'ID: $otherUserId');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discussions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implémenter la recherche
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Implémenter le menu
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _conversations.isEmpty
                  ? const Center(
                      child: Text('Aucune conversation'),
                    )
                  : ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final user = _findUserForConversation(conversation);
                        return _buildConversationTile(
                            context, conversation, user);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {Navigator.pushNamed(context, '/contact')},
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    Users? user,
  ) {
    final bool isGroup = conversation.isGroup;
    final String displayName =
        isGroup ? conversation.name : (user?.fullname ?? 'Utilisateur inconnu');
    print("----------------------------------------$user");

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: conversation.avatarUrl != null
            ? NetworkImage(conversation.avatarUrl!)
            : null,
        child: conversation.avatarUrl == null
            ? Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20),
              )
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: conversation.lastMessageContent != null
          ? Text(
              _buildLastMessagePreview(conversation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatLastMessageTime(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0 ? Colors.green : Colors.grey,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              contactName: displayName,
              avatarUrl: conversation.avatarUrl ?? '',
              conversationId: conversation.id,
              currentUserId: widget.currentUserId,
              receiverId: '',
            ),
          ),
        );
      },
    );
  }

  String _buildLastMessagePreview(Conversation conversation) {
    if (conversation.lastMessageContent == null) {
      return 'Aucun message';
    }

    String prefix =
        conversation.isGroup ? '${conversation.lastMessageSender}: ' : '';
    String content = '';

    switch (conversation.lastMessageType) {
      case MessageType.text:
        content = conversation.lastMessageContent!;
        break;
      case MessageType.image:
        content = '📷 Photo';
        break;
      case MessageType.audio:
        content = '🎵 Audio';
        break;
      case MessageType.video:
        content = '🎥 Vidéo';
        break;
      case MessageType.file:
        content = '📎 Fichier';
        break;
      case MessageType.voice:
        content = '🎤 Message vocal';
        break;
      case MessageType.location:
        content = '📍 Position';
        break;
      default:
        content = 'Message';
    }

    return prefix + content;
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (difference.inDays > 0) {
      switch (difference.inDays) {
        case 1:
          return 'Hier';
        case 7:
          return 'Il y a 1 semaine';
        default:
          return 'Il y a ${difference.inDays} jours';
      }
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

// Ajout de la classe Users si elle n'existe pas déjà
class Users {
  final String id;
  final String fullname;
  final String email;
  final String password;
  final double height;
  final double weight;

  Users({
    required this.id,
    required this.fullname,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
  });
}
