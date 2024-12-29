import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

/* Prise de photos */
Future<File?> pickImage() async {
  final ImagePicker picker = ImagePicker();
  XFile? xFile = await picker.pickImage(source: ImageSource.camera);
  if (xFile != null) {
    return File(xFile.path);
  }
  return null;
}

/* Enregistrement vocal */
FlutterSoundRecorder? _recorder;

Future<void> startRecording() async {
  _recorder = FlutterSoundRecorder();

  try {
    // Vérifier les permissions
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      throw RecordingPermissionException('Permission micro refusée');
    }

    // Initialiser l'enregistreur
    await _recorder!.openRecorder();

    // Commencer l'enregistrement
    await _recorder!.startRecorder(
      toFile: 'audio_${DateTime.now().millisecondsSinceEpoch}.aac',
      codec: Codec.aacADTS,
    );
  } catch (e) {
    print("Erreur lors de l'enregistrement : $e");
    rethrow; // Pour relancer l'erreur si nécessaire
  }
}

Future<String?> stopRecording() async {
  if (_recorder != null && _recorder!.isRecording) {
    String? path = await _recorder!.stopRecorder();
    await _recorder!.closeRecorder();
    _recorder = null;
    return path;
  }
  return null;
}

/* Afficher un message en bas */
void downMessage(BuildContext context, Icon icon, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          icon,
          const SizedBox(
            width: 3,
          ),
          Text(message),
        ],
      ),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/* Unfocus */
void unFocusMethod(BuildContext context) {
  FocusScope.of(context).unfocus();
}

/* Champs de formulaire */
Padding createField(
    BuildContext context,
    String label,
    String placehover,
    bool blur,
    TextEditingController controllerField,
    TextInputType inputType,
    int minLength,
    int? maxLength) {
  return Padding(
    padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.07,
        MediaQuery.of(context).size.height * 0.001,
        MediaQuery.of(context).size.width * 0.07,
        MediaQuery.of(context).size.height * 0.02),
    child: TextFormField(
      controller: controllerField,
      maxLength: maxLength,
      validator: (value) {
        if (value == null || value.toString().trim().isEmpty) {
          return 'Please enter your $label';
        } else if (value.toString().trim().length < minLength) {
          return 'Minimum $minLength required !';
        }
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        label: Text(label),
        hintText: placehover,
      ),
      obscureText: blur,
      keyboardType: inputType,
    ),
  );
}

void lienExterne(String link) async {
  final Uri url = Uri.parse(link);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}

double calculerIMC(double weight, double height) {
  // Convertir la taille de cm en m
  double tailleEnMetres = height / 100;

  // Calculer l'IMC
  double imc = weight / (tailleEnMetres * tailleEnMetres);

  return imc;
}

String interpreterIMC(double imc) {
  if (imc < 16) {
    return "Severe undernutrition";
  } else if (imc < 16.9) {
    return "Moderate undernutrition";
  } else if (imc < 18.4) {
    return "Mild undernutrition";
  } else if (imc < 24.9) {
    return "Normal weight";
  } else if (imc < 29.9) {
    return "Overweight";
  } else if (imc < 34.9) {
    return "Moderate obesity";
  } else if (imc < 39.9) {
    return "Severe obesity";
  } else {
    return "Morbid obesity";
  }
}

String recommandationIMC(double imc) {
  if (imc < 16) {
    return "Please consult a doctor as soon as possible.";
  } else if (imc < 16.9) {
    return "Consider increasing your caloric intake.";
  } else if (imc < 18.4) {
    return "Focus on a balanced diet to gain weight healthily.";
  } else if (imc < 24.9) {
    return "Maintain your current healthy lifestyle.";
  } else if (imc < 29.9) {
    return "Try to incorporate regular exercise and balanced meals.";
  } else if (imc < 34.9) {
    return "Consider reducing your daily caloric intake and increasing physical activity.";
  } else if (imc < 39.9) {
    return "It's important to consult a healthcare professional for a weight management plan.";
  } else {
    return "Seek immediate medical advice for a comprehensive weight management strategy.";
  }
}
