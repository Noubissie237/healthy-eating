import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/chat.dart';
import 'package:food_app/models/users.dart';
import 'package:food_app/pages/conversation_page.dart';
import 'package:food_app/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

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
  Set<String> _selectedConversations =
      {}; // Pour gérer les conversations sélectionnées
  bool _isSelectionMode = false; // Pour gérer le mode de sélection

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

      // Debug print
      print("Loaded conversations: ${results[0]!.length}");
      print("Loaded users: ${results[1]!.length}");

      // Pour chaque conversation, affichons les participants
      for (var conv in results[0] as List<Conversation>) {
        print("Conversation ${conv.id} participants: ${conv.participantIds}");
      }

      // Pour chaque utilisateur, affichons l'ID et le nom
      for (var user in results[1] as List<Users>) {
        print("User ${user.id}: ${user.fullname}");
      }

      setState(() {
        _conversations = results[0] as List<Conversation>;
        _users = results[1] as List<Users>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur lors du chargement des données: $e');
    }
  }

  // Nouvelle méthode pour gérer la suppression
  Future<void> _deleteSelectedConversations() async {
    try {
      for (String conversationId in _selectedConversations) {
        await _dbHelper.deleteMessagesForConversation(conversationId);
        await _dbHelper.deleteConversation(conversationId);
      }

      setState(() {
        _conversations
            .removeWhere((conv) => _selectedConversations.contains(conv.id));
        _selectedConversations.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversations deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suppression Failed')),
        );
      }
    }
  }

  // Méthode pour gérer l'appui prolongé
  void _onLongPress(String conversationId) {
    setState(() {
      _isSelectionMode = true;
      _selectedConversations.add(conversationId);
    });
  }

  // Méthode pour gérer la sélection/désélection
  void _onTapInSelectionMode(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
        if (_selectedConversations.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_isSelectionMode
            ? const Text(
                'Discussions',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : Text(
                '${_selectedConversations.length} selected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete conversations'),
                          content: const Text(
                              'Are you sure you want to delete selected conversations ?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: MyColors.failed),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _deleteSelectedConversations();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedConversations.clear();
                      _isSelectionMode = false;
                    });
                  },
                ),
              ]
            : [
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'invite',
                      child: TextButton(
                        onPressed: () {
                          Share.share(
                              "Download the Health Food App at : \n\nhttps://www.simpletraining.online/app-release.apk");
                        },
                        child: const Text("Invite friends"),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: TextButton(
                        onPressed: () {
                          lienExterne("https://wa.me/+237690232120");
                        },
                        child: const Text("Help"),
                      ),
                    ),
                  ],
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
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () => {Navigator.pushNamed(context, '/contact')},
              child: const Icon(Icons.message),
            )
          : null,
    );
  }

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return '?';

    final parts = displayName.split(' ');
    if (parts.length == 1) {
      // Si un seul mot, prendre les deux premières lettres ou juste la première
      return displayName.length > 1
          ? '${displayName[0]}${displayName[1]}'.toUpperCase()
          : displayName[0].toUpperCase();
    }

    // Si plusieurs mots, prendre la première lettre du premier et du dernier mot
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    Users? user,
  ) {
    final bool isGroup = conversation.isGroup;
    final String displayName =
        isGroup ? conversation.name : (user?.fullname ?? 'You(👮‍♂️)');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
              radius: 28,
              child: Text(
                _getInitials(displayName),
                style: const TextStyle(fontSize: 20),
              )),
          if (_isSelectionMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedConversations.contains(conversation.id)
                      ? Colors.green
                      : Colors.grey.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _selectedConversations.contains(conversation.id)
                      ? Icons.check
                      : Icons.circle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
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
      trailing: !_isSelectionMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatLastMessageTime(conversation.lastMessageAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: conversation.unreadCount > 0
                        ? Colors.green
                        : Colors.grey,
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
            )
          : null,
      onLongPress: () => _onLongPress(conversation.id),
      onTap: () {
        if (_isSelectionMode) {
          _onTapInSelectionMode(conversation.id);
        } else {
          // Trouver l'autre participant
          final otherUserId = conversation.participantIds.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => '',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                contactName: displayName,
                avatarUrl: conversation.avatarUrl ?? '',
                conversationId: conversation.id,
                currentUserId: widget.currentUserId,
                receiverId: otherUserId,
              ),
            ),
          );
        }
      },
    );
  }

  Users? _findUserForConversation(Conversation conversation) {
    // Si c'est un groupe, pas besoin de chercher un utilisateur
    if (conversation.isGroup) {
      return null;
    }

    // Protection contre les listes vides
    if (conversation.participantIds.isEmpty) {
      print(
          "Warning: Empty participants list for conversation ${conversation.id}");
      return null;
    }

    // Trouvons l'ID de l'autre participant
    String? otherUserId;
    try {
      // Vérifions d'abord si la liste contient l'ID de l'utilisateur courant
      if (!conversation.participantIds.contains(widget.currentUserId)) {
        print(
            "Warning: Current user ${widget.currentUserId} not in participants");
        // Dans ce cas, prenons simplement le premier participant
        otherUserId = conversation.participantIds.first;
      } else {
        otherUserId = conversation.participantIds
            .firstWhere((id) => id != widget.currentUserId);
      }
    } catch (e) {
      print('Error finding other participant: $e');
      return null;
    }

    // Debuggons les utilisateurs disponibles
    print("Looking for user with ID: $otherUserId");
    print(
        "Available users: ${_users.map((u) => '${u.id}: ${u.fullname}').join(', ')}");

    // Cherchons l'utilisateur correspondant
    try {
      final user = _users.firstWhere(
        (user) => user.id.toString() == otherUserId,
        orElse: () {
          print("No user found with ID: $otherUserId");
          return Users(
            // Remplacez avec votre constructeur Users réel
            id: int.parse(otherUserId!),
            fullname: "User $otherUserId", email: '', avatar: '',
            password: '', // Fallback plus informatif
            // Ajoutez d'autres champs requis
          );
        },
      );
      return user;
    } catch (e) {
      print('Error finding user: $e');
      return null;
    }
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
          return 'Yerterday';
        case 7:
          return '1 week ago';
        default:
          return '${difference.inDays} days ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min ago';
    } else {
      return 'Now';
    }
  }
}
