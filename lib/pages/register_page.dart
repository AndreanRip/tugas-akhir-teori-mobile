import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart'; // Tetap gunakan untuk PBKDF2
import 'dart:convert';
import 'dart:math';

import '../db_helper.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _dbHelper = DatabaseHelper();

  String hashPassword(String password) {
    final salt = _generateSalt(); // Salt random
    final key = pbkdf2(password, salt, 1000, 32); // PBKDF2 dengan 1000 iterasi
    return base64.encode(key) + ':' + base64.encode(salt);
  }

  List<int> pbkdf2(String password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var output = List<int>.filled(keyLength, 0);
    var block = hmac.convert(salt).bytes;

    for (int i = 1; i <= iterations; i++) {
      block = hmac.convert(block).bytes;
      for (int j = 0; j < block.length; j++) {
        output[j % keyLength] ^= block[j];
      }
    }
    return output;
  }

  List<int> _generateSalt([int length = 16]) {
    final random = Random.secure();
    return List<int>.generate(length, (i) => random.nextInt(256));
  }

  Future<void> _register() async {
    String username = _usernameController.text;
    String password = hashPassword(_passwordController.text);

    final user = await _dbHelper.getUser(username);
    if (user != null) {
      _showMessage('Username already exists');
    } else {
      await _dbHelper.addUser(username, password);

      _showMessage('User registered successfully');
      Navigator.pop(context); // Kembali ke halaman login
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/image/eleanor.png', height: 100), // Tambahkan logo
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
