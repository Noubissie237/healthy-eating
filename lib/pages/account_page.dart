import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  final Map<String, String> userInfo;

  const AccountPage({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations Personnelles"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/images/user.webp'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 18,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              buildInfoTile(context, "Nom", userInfo["nom"] ?? "Inconnu"),
              buildInfoTile(context, "Prénom", userInfo["prenom"] ?? "Inconnu"),
              buildInfoTile(context, "Téléphone", userInfo["telephone"] ?? "Inconnu"),
              buildInfoTile(context, "Email", userInfo["email"] ?? "Inconnu"),
              buildInfoTile(context, "Taille (cm)", userInfo["taille"] ?? "Inconnu"),
              buildInfoTile(context, "Poids (Kg)", userInfo["poids"] ?? "Inconnu"),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoTile(BuildContext context, String title, String value) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 18,
          ),
        ),
        Divider(color: Colors.grey[300]),
      ],
    );
  }
}

