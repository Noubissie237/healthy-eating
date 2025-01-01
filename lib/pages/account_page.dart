import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, String>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _getUserInfo();
  }

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> userInfo = {};
    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      userInfo = {
        'fullname': decodedToken['fullname'] ?? 'Unknown',
        'avatar': decodedToken['avatar'] ?? 'assets/images/default-img.png',
        'email': decodedToken['email'] ?? 'Unknown',
        'height': decodedToken['height']?.toString() ?? 'Unknown',
        'weight': decodedToken['weight']?.toString() ?? 'Unknown',
      };
    }
    return userInfo;
  }

  Future<void> _refreshUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      final String email = decodedToken['email'];

      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserByEmail(email);

      if (userData != null) {
        decodedToken['height'] = userData['height']?.toString();
        decodedToken['weight'] = userData['weight']?.toString();
        await prefs.setString('user_token', jsonEncode(decodedToken));
      }
    }

    setState(() {
      _userInfoFuture = _getUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading data",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final userInfo = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshUserInfo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(userInfo),
                  const SizedBox(height: 20),
                  _buildInfoSection(userInfo, context),
                  const SizedBox(height: 20),
                  _buildStatsSection(userInfo, context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageModal(BuildContext context, String userEmail) {
    final List<String> images = [
      'assets/images/default-img.png',
      'assets/images/image-ball.png',
      'assets/images/image-casque.jpg',
      'assets/images/image-dog.png',
      'assets/images/image-rabbit.png',
      'assets/images/image-woman.jpg',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barre de poignée
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Choose your avatar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Grille d'images
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: images.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildImageItem(context, images[index], userEmail);
                    },
                  ),
                ),
              ),
              // Bouton de fermeture
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageItem(BuildContext context, String imagePath, String email) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _updateImage(context, imagePath, email);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, String> userInfo) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(158, 158, 158, 0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage(userInfo['avatar']!),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                    onPressed: () =>
                        _showImageModal(context, userInfo['email']!),
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userInfo['fullname'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userInfo['email'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, String> userInfo, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(158, 158, 158, 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Personal Information",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.person_outline,
            title: "Full Name",
            value: userInfo["fullname"] ?? "Unknown",
            onTap: () => _showLockedFieldMessage(context),
          ),
          _buildInfoTile(
            icon: Icons.email_outlined,
            title: "Email",
            value: userInfo["email"] ?? "Unknown",
            onTap: () => _showLockedFieldMessage(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      Map<String, String> userInfo, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(158, 158, 158, 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Body Measurements",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.height,
            title: "Height",
            value: "${userInfo["height"] ?? "Unknown"} cm",
            isEditable: true,
            onTap: () => _showHeightDialog(
                context, userInfo["height"], userInfo["email"]),
          ),
          _buildInfoTile(
            icon: Icons.monitor_weight_outlined,
            title: "Weight",
            value: "${userInfo["weight"] ?? "Unknown"} kg",
            isEditable: true,
            onTap: () => _showWeightDialog(
                context, userInfo["weight"], userInfo["email"]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isEditable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(3, 218, 198, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: MyColors.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  void _showLockedFieldMessage(BuildContext context) {
    downMessage(
      context,
      const Icon(Icons.lock_outline, color: MyColors.primaryColor),
      'This field cannot be modified',
    );
  }

  void _showHeightDialog(
      BuildContext context, String? currentHeight, String? email) {
    final TextEditingController heightController = TextEditingController();
    if (currentHeight != null && currentHeight != "Unknown") {
      heightController.text = currentHeight;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Update Height",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Height (cm)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.height),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  _updateHeight(context, heightController.text, email),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showWeightDialog(
      BuildContext context, String? currentWeight, String? email) {
    final TextEditingController weightController = TextEditingController();
    if (currentWeight != null && currentWeight != "Unknown") {
      weightController.text = currentWeight;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Update Weight",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Weight (kg)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.monitor_weight_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  _updateWeight(context, weightController.text, email),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateHeight(
      BuildContext context, String heightStr, String? email) async {
    final newHeight = double.tryParse(heightStr);
    if (newHeight != null && email != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateHeight(email, newHeight);
      await _updateUserToken('height', newHeight);
      setState(() {
        _userInfoFuture = _getUserInfo();
      });
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid height")),
      );
    }
  }

  Future<void> _updateWeight(
      BuildContext context, String weightStr, String? email) async {
    final newWeight = double.tryParse(weightStr);
    if (newWeight != null && email != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateWeight(email, newWeight);
      await _updateUserToken('weight', newWeight);
      setState(() {
        _userInfoFuture = _getUserInfo();
      });
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid weight")),
      );
    }
  }

  Future<void> _updateImage(
      BuildContext context, String newImg, String? email) async {
    if (email != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateImage(email, newImg);
      await _updateUserToken('avatar', newImg);
      setState(() {
        _userInfoFuture = _getUserInfo();
      });
      Navigator.of(context).pop();
      print("Avatar changed");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occured !")),
      );
    }
  }

  Future<void> _updateUserToken(String field, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      decodedToken[field] = value;
      await prefs.setString('user_token', jsonEncode(decodedToken));
    }
  }
}
