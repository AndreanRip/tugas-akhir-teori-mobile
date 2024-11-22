import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../helpers/session.dart';
import 'detail_cart_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (Session.currentUserId == null) {
      setState(() {
        _cartItems = [];
      });
      return;
    }

    final items = await _dbHelper.getCartForUser(Session.currentUserId!);
    setState(() {
      _cartItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: _cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return ListTile(
            leading: Image.network(
              item['image_url'] ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image, color: Colors.grey),
            ),
            title: Text(item['title']),
            subtitle: Text('Episodes: ${item['episodes']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                // Panggil fungsi untuk menghapus item
                await _dbHelper.removeItemFromCart(Session.currentUserId!, item['anime_id']);

                // Perbarui tampilan setelah penghapusan
                setState(() {
                  _cartItems.removeAt(index);
                });

                // Tampilkan snackbar sebagai feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} removed from cart')),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailCartPage(animeId: item['anime_id']),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => ProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
