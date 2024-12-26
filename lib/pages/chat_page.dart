import 'package:flutter/material.dart';
import 'package:food_app/pages/conversation_page.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  // Données de démonstration pour les conversations
  final List<ChatConversation> conversations = [
    ChatConversation(
      name: "Marie Martin",
      lastMessage: "On se voit demain alors ?",
      time: "10:30",
      unreadCount: 2,
      avatarUrl: "https://example.com/avatar1.jpg",
    ),
        ChatConversation(
      name: "Marie Martin",
      lastMessage: "On se voit demain alors ?",
      time: "10:30",
      unreadCount: 2,
      avatarUrl: "https://example.com/avatar1.jpg",
    ),
    ChatConversation(
      name: "Groupe Famille",
      lastMessage: "Papa: J'ai envoyé les photos du weekend",
      time: "09:15",
      unreadCount: 5,
      avatarUrl: "https://example.com/avatar2.jpg",
    ),
    ChatConversation(
      name: "Thomas Dubois",
      lastMessage: "Merci pour l'info !",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar3.jpg",
    ),
    ChatConversation(
      name: "Julie Bernard",
      lastMessage: "J'arrive dans 5 minutes",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar4.jpg",
    ),
    ChatConversation(
      name: "Bureau",
      lastMessage: "Sophie: La réunion est reportée à 14h",
      time: "Lun",
      unreadCount: 3,
      avatarUrl: "https://example.com/avatar5.jpg",
    ),
        ChatConversation(
      name: "Marie Martin",
      lastMessage: "On se voit demain alors ?",
      time: "10:30",
      unreadCount: 2,
      avatarUrl: "https://example.com/avatar1.jpg",
    ),
    ChatConversation(
      name: "Groupe Famille",
      lastMessage: "Papa: J'ai envoyé les photos du weekend",
      time: "09:15",
      unreadCount: 5,
      avatarUrl: "https://example.com/avatar2.jpg",
    ),
    ChatConversation(
      name: "Thomas Dubois",
      lastMessage: "Merci pour l'info !",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar3.jpg",
    ),
    ChatConversation(
      name: "Julie Bernard",
      lastMessage: "J'arrive dans 5 minutes",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar4.jpg",
    ),
    ChatConversation(
      name: "Bureau",
      lastMessage: "Sophie: La réunion est reportée à 14h",
      time: "Lun",
      unreadCount: 3,
      avatarUrl: "https://example.com/avatar5.jpg",
    ),
        ChatConversation(
      name: "Marie Martin",
      lastMessage: "On se voit demain alors ?",
      time: "10:30",
      unreadCount: 2,
      avatarUrl: "https://example.com/avatar1.jpg",
    ),
    ChatConversation(
      name: "Groupe Famille",
      lastMessage: "Papa: J'ai envoyé les photos du weekend",
      time: "09:15",
      unreadCount: 5,
      avatarUrl: "https://example.com/avatar2.jpg",
    ),
    ChatConversation(
      name: "Thomas Dubois",
      lastMessage: "Merci pour l'info !",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar3.jpg",
    ),
    ChatConversation(
      name: "Julie Bernard",
      lastMessage: "J'arrive dans 5 minutes",
      time: "Hier",
      unreadCount: 0,
      avatarUrl: "https://example.com/avatar4.jpg",
    ),
    ChatConversation(
      name: "Bureau",
      lastMessage: "Sophie: La réunion est reportée à 14h",
      time: "Lun",
      unreadCount: 3,
      avatarUrl: "https://example.com/avatar5.jpg",
    ),
  ];

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
      body: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationTile(context, conversation); // Ajout du paramètre context
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/contact');
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ChatConversation conversation) { // Ajout du paramètre context
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(conversation.avatarUrl),
        child: conversation.avatarUrl.isEmpty
            ? Text(conversation.name[0], style: const TextStyle(fontSize: 20))
            : null,
      ),
      title: Text(
        conversation.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.time,
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
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              contactName: conversation.name,
              avatarUrl: conversation.avatarUrl,
            ),
          ),
        );
      },
    );
  }
}

class ChatConversation {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String avatarUrl;

  ChatConversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
  });
}