import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
//import 'package:food_app/database/database_helper.dart';
//import 'package:food_app/models/users.dart';
import 'package:food_app/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePage();
  }
}

class _HomePage extends State<HomePage> {
  File? _imageFile;
  String? _audioPath;
  bool _isRecording = false;
  //final DatabaseHelper _databaseHelper = DatabaseHelper();
  //late Future<List<Users>> _students;

  @override
  void initState() {
    super.initState();
   // _students = _databaseHelper.getUsers();
  }

  Future<void> _handlePickImage() async {
    File? image = await pickImage();
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
      print("Chemin de l'image : ${image.path} - image : $_imageFile");
    }
  }

  Future<void> _handleRecordAudio() async {
    if (_isRecording) {
      String? path = await stopRecording();
      if (path != null) {
        setState(() {
          _audioPath = path;
          print("$_audioPath");
          _isRecording = false;
        });
        print("Enregistrement terminé : $path");
      }
    } else {
      try {
        await startRecording();
        setState(() {
          _isRecording = true;
        });
        print("Enregistrement en cours...");
      } catch (e) {
        print("Erreur lors de l'enregistrement : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        elevation: 8,
        // backgroundColor: MyColors.primaryColor,
        title: Image.asset('assets/images/logo.png', width: 100),
        actions: [
          IconButton(
            onPressed: _handlePickImage,
            icon: const Icon(Icons.camera_alt, color: MyColors.textColor),
          ),
          IconButton(
            onPressed: _handleRecordAudio,
            icon: Icon(_isRecording ? Icons.mic_off : Icons.mic,
                color: MyColors.textColor),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/recordings');
            },
            icon: const Icon(Icons.chat, color: MyColors.textColor),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            icon: const Icon(Icons.person_add_alt_rounded,
                color: MyColors.textColor),
          ),
        ],
      ),
      // body: FutureBuilder(
      //   future: _students,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //     } else if (snapshot.hasError) {
      //       return Center(
      //         child: Text('Error: ${snapshot.error}'),
      //       );
      //     } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      //       return const Center(
      //         child: Text('No user found!'),
      //       );
      //     }
      //     final users = snapshot.data!;
      //     return Center(
      //       child: SingleChildScrollView(
      //         scrollDirection: Axis.horizontal,
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: users.map<Widget>((user) {
      //             return Padding(
      //               padding: const EdgeInsets.symmetric(horizontal: 8.0),
      //               child: Column(
      //                 mainAxisSize: MainAxisSize.min,
      //                 children: [
      //                   CircleAvatar(
      //                     radius: 30,
      //                     backgroundColor: Colors.grey.shade300,
      //                     child: ClipOval(
      //                         child: Image.asset(
      //                       'assets/images/default-user.png',
      //                       fit: BoxFit.cover,
      //                       width: 100,
      //                       height: 100,
      //                     )),
      //                   ),
      //                   const SizedBox(height: 8),
      //                   Text(
      //                     user.fullname,
      //                     style: const TextStyle(
      //                       fontSize: 16,
      //                       fontWeight: FontWeight.w500,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             );
      //           }).toList(),
      //         ),
      //       ),
      //     );
      //   },
      // ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/contact');
      //   },
      //   tooltip: 'Contacts',
      //   backgroundColor: MyColors.secondaryColor,
      //   child: const Icon(Icons.message_rounded),
      // ),
    );
  }
}
