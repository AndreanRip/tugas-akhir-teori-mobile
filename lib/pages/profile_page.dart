import 'package:flutter/material.dart';
import '../helpers/session.dart';
import '../db_helper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _userData; // Data pengguna (hanya username)
  List<Map<String, dynamic>> _favoriteAnimes = []; // Daftar anime favorit

  // Statistik
  final String _nim = '124220071'; // Contoh NIM statis
  final String _birthPlace = 'Samarinda'; // Contoh tempat lahir
  final String _birthDate = '04 January 2004'; // Contoh tanggal lahir
  final String _hobby = 'Membaca Novel, Menonton Anime'; // Contoh hobi

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userId = Session.currentUserId;
    if (userId == null) return;

    // Ambil username pengguna
    final user = await _dbHelper.getUserById(userId);

    // Ambil daftar anime favorit pengguna
    final favoriteAnimes = await _dbHelper.getFavoriteAnimes(userId);

    setState(() {
      _userData = user;
      _favoriteAnimes = favoriteAnimes;
    });
  }

  void _logout(BuildContext context) {
    Session.logout(); // Hapus session
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _userData == null
          ? Center(child: CircularProgressIndicator()) // Tampilkan loading jika data belum ada
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gambar Profile
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/image/eleanor.png'),
                onBackgroundImageError: (_, __) =>
                    Icon(Icons.person, size: 100), // Placeholder jika gambar gagal
              ),
              SizedBox(height: 16),

              // Nama pengguna
              Text(
                _userData!['username'] ?? 'Unknown',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Informasi tambahan (statis)
              Text('NIM: $_nim', style: TextStyle(fontSize: 16)),
              Text(
                'Tempat/Tgl Lahir: $_birthPlace, $_birthDate',
                style: TextStyle(fontSize: 16),
              ),
              Text('Hobi: $_hobby', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),

              // Daftar Anime Favorit
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Anime Favorit:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),

              _favoriteAnimes.isEmpty
                  ? Text('Belum ada anime favorit.', style: TextStyle(fontSize: 16))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _favoriteAnimes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_favoriteAnimes[index]['title']),
                  );
                },
              ),
              SizedBox(height: 16),

              // Tombol Logout
              ElevatedButton(
                onPressed: () => _logout(context),
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
