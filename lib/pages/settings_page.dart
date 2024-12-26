import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Paramètres', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/user.webp'),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wilfried Noubissie',
                          style: TextStyle(
                            fontSize: 22,
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: MyColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Share.share(
                    "Télécharger l'application Health Food à l'adresse : \n\nhttps://www.simpletraining.online/app-release.apk");
              },
              icon: Icon(Icons.favorite),
              label: Text('Invite friends'),
            ),
            SizedBox(height: 16.0),
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
                'STATISTIQUES',
                style: TextStyle(
                  color: MyColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              onTap: () {},
            ),
            Divider(),
            SettingsSection(
              title: 'Mon Compte',
              icon: Icons.person,
              onTap: () {
                Navigator.pushNamed(context, '/account');
              },
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
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_token');

                // Redirection vers la page de connexion
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
