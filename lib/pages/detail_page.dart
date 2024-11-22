import 'package:flutter/material.dart';
import '../models/anime_model.dart';
import '../db_helper.dart';
import '../helpers/session.dart';

class DetailPage extends StatelessWidget {
  final Anime anime;

  const DetailPage({Key? key, required this.anime}) : super(key: key);

  Future<void> _toggleCart(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    if (Session.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to modify your cart')),
      );
      return;
    }

    // Periksa apakah anime sudah ada di cart
    final existing = await dbHelper.getAnimeInCart(Session.currentUserId!, anime.id);
    if (existing != null) {
      // Jika sudah ada, hapus dari cart
      await dbHelper.removeAnimeFromCart(Session.currentUserId!, anime.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anime removed from cart')),
      );
    } else {
      // Jika belum ada, tambahkan ke cart
      await dbHelper.addAnime(
        Session.currentUserId!,
        anime,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anime added to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(anime.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Anime
            Image.network(
              anime.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey,
                  child: Center(
                    child: Text(
                      'Image not available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Anime
                  Text(
                    anime.title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Informasi Episode
                  Text(
                    'Episodes: ${anime.episodes ?? "Unknown"}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),

                  // Sinopsis
                  Text(
                    anime.synopsis ?? 'No synopsis available.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),

                  // Tombol Cart
                  ElevatedButton.icon(
                    onPressed: () => _toggleCart(context),
                    icon: Icon(Icons.shopping_cart),
                    label: Text('Add/Remove from Cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
