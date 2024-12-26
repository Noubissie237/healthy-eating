import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> userInfo = {};
    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      userInfo = {
        'email': decodedToken['email'] ?? 'Unknown',
      };
    }
    return userInfo;
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userInfo = await _getUserInfo();
        final email = userInfo['email'];

        if (email == null) {
          throw Exception('User email not found');
        }

        final dbHelper = DatabaseHelper();

        // Vérifier l'ancien mot de passe
        final isValidPassword = await dbHelper.verifyUser(
          email,
          _oldPasswordController.text,
        );

        if (!isValidPassword) {
          throw Exception('Incorrect old password');
        }

        // Mettre à jour le mot de passe
        await dbHelper.updatePassword(
          email,
          _newPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Update password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              maxLength: 4,
              controller: _oldPasswordController,
              obscureText: _obscureOldPassword,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Old password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOldPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _obscureOldPassword = !_obscureOldPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your old password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              keyboardType: TextInputType.number,
              obscureText: _obscureNewPassword,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a new password';
                }
                if (value.length < 4) {
                  return 'Minimum 4 caracters required !';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLength: 4,
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Password doesn\'t match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Update your password',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
