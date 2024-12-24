import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  late FlutterSoundPlayer _player;
  bool _isPlaying = false;
  String? _currentPlayingFile;

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<List<File>> _fetchRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(directory.path);
    final files = folder.listSync().whereType<File>().toList();

    // Filtrer les fichiers audio (par exemple, fichiers .aac)
    return files.where((file) => file.path.endsWith('.aac')).toList();
  }

  Future<void> _playRecording(String path) async {
    if (_isPlaying && _currentPlayingFile == path) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _currentPlayingFile = null;
      });
    } else {
      await _player.startPlayer(fromURI: path);
      setState(() {
        _isPlaying = true;
        _currentPlayingFile = path;
      });
      // _player.onPlayerComplete = () {
      //   setState(() {
      //     _isPlaying = false;
      //     _currentPlayingFile = null;
      //   });
      // };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes enregistrements'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<File>>(
        future: _fetchRecordings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement des enregistrements.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun enregistrement trouvé.'));
          } else {
            final recordings = snapshot.data!;
            return ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final file = recordings[index];
                final fileName = file.path.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.audiotrack, color: Colors.blue),
                  title: Text(fileName),
                  trailing: IconButton(
                    icon: Icon(
                      _isPlaying && _currentPlayingFile == file.path
                          ? Icons.stop
                          : Icons.play_arrow,
                      color: Colors.green,
                    ),
                    onPressed: () => _playRecording(file.path),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
