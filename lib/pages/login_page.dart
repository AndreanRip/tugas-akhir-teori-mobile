import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:collection/collection.dart';
import '../db_helper.dart';
import '../helpers/session.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbHelper = DatabaseHelper();

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

  bool validatePassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    final hash = base64.decode(parts[0]);
    final salt = base64.decode(parts[1]);
    final key = pbkdf2(password, salt, 1000, hash.length);
    return ListEquality().equals(key, hash);
  }

  Future<void> _login() async {
    final user = await _dbHelper.getUser(_usernameController.text);
    if (user != null && validatePassword(_passwordController.text, user['password'])) {
      // Validasi password berhasil
      Session.login(user['id']);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Validasi password gagal
      _showMessage('Invalid username or password');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isImage1 = true; // Variabel untuk menyimpan status gambar

  // Fungsi untuk mengganti gambar
  void _toggleImage() {
    setState(() {
      _isImage1 = !_isImage1; // Toggle antara true dan false
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView( // Tambahkan SingleChildScrollView untuk memungkinkan scroll
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ani List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[700], // Warna teks ungu tua
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleImage, // Event klik pada gambar
                child: Container(
                  padding: EdgeInsets.all(4.0), // Spasi antara border dan gambar
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurple[700]!, // Border ungu tua
                      width: 4.0,
                    ),
                    borderRadius: BorderRadius.circular(12), // Border melingkar
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Border pada gambar
                    child: Image.asset(
                      _isImage1 ? 'assets/image/eleanor.png' : 'assets/image/eleanor_horror.png', // Gambar berubah
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 20), // Tambahkan padding antara Username dan Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20), // Tambahkan padding sebelum tombol Login
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
