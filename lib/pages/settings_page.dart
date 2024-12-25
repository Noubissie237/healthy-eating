import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        AssetImage('assets/images/default-student.png'),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wilfried Noubissie',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '690232120',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Share.share(
                      "Télécharger l'application Health Food à l'adresse : \n\nhttps://www.simpletraining.online/app-release.apk");
                },
                icon: Icon(Icons.favorite, color: MyColors.primaryColor),
                label: Text(
                  'Invite friends',
                  style: TextStyle(color: MyColors.primaryColor),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width * 0.1),
            Divider(),
            SettingsSection(
              title: 'Help',
              icon: Icons.help,
              onTap: () => lienExterne("https://wa.me/+237690232120"),
            ),
            Divider(),
            SettingsSection(
              title: 'Mon Historique',
              icon: Icons.auto_graph,
              trailing: Text(
                'STATISTIQUE',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {},
            ),
            Divider(),
            SettingsSection(
              title: 'Mon Compte',
              icon: Icons.person,
              onTap: () {},
            ),
            Divider(),
            SettingsSection(
              title: 'Securité',
              icon: Icons.security,
              onTap: () {},
            ),
            Divider(),
            SettingsSection(
              title: 'Déconnexion',
              icon: Icons.logout,
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/signin', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
