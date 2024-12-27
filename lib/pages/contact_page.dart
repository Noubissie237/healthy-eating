import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/users.dart';
import 'package:food_app/pages/conversation_page.dart';
import 'package:food_app/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Pour générer un ID de conversation unique

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<StatefulWidget> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late Future<List<Users>> _users;
  final TextEditingController _searchController = TextEditingController();
  List<Users> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _users = _databaseHelper.getUsers();
  }

  void _filterUsers(String query, List<Users> allUsers) {
    setState(() {
      _filteredUsers = allUsers
          .where((user) =>
              user.fullname.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToConversation(BuildContext context, Users user) async {
    // Générer un ID de conversation unique
    final conversationId = const Uuid().v4();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    final Map<String, dynamic> decodedToken;
    String userID = '';

    if (token != null) {
      decodedToken = jsonDecode(token);
      userID = decodedToken['id'].toString();
    }

    // Vous devrez adapter cette partie en fonction de votre système d'authentification
    final currentUserId = userID; // Remplacez par l'ID de l'utilisateur actuel

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(
          contactName: user.fullname,
          avatarUrl:
              "https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.fullname)}", // Utilise un service d'avatar par défaut
          conversationId: conversationId,
          currentUserId: currentUserId,
          receiverId: user.id!.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: !_isSearching
            ? Text(
                "Select contact",
                style: TextStyle(
                  color: MyColors.textColor,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                ),
              )
            : TextField(
                controller: _searchController,
                style: TextStyle(color: MyColors.textColor),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: MyColors.textColor),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  _users.then((users) => _filterUsers(query, users));
                },
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredUsers.clear();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'invite',
                child: TextButton(
                  onPressed: () {
                    Share.share(
                        "Download the Health Food App at : \n\nhttps://www.simpletraining.online/app-release.apk");
                  },
                  child: Text("Invite friends"),
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: TextButton(
                  onPressed: () {
                    lienExterne("https://wa.me/+237690232120");
                  },
                  child: Text("Help"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF075E54),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé !'));
          }

          final users = _isSearching && _filteredUsers.isNotEmpty
              ? _filteredUsers
              : snapshot.data!;

          return ListView.builder(
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Contacts',
                        style: TextStyle(
                          color: Color(0xFF075E54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }

              final user = users[index - 1];
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF075E54),
                      child: Text(
                        user.fullname[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user.fullname,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () => _navigateToConversation(context, user),
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
