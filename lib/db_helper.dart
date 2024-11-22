import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'models/anime_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'anime_app.db'),
      version: 2, // Tingkatkan versi
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
      ''');

        await db.execute('''
        CREATE TABLE anime_cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          anime_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          image_url TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          score REAL,
          status TEXT,
          type TEXT,
          airing_start TEXT,
          source TEXT,
          genres TEXT,
          duration_minutes INTEGER,
          members INTEGER,
          favorites INTEGER,
          studios TEXT,
          episodes INTEGER,
          synopsis TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          UNIQUE(user_id, anime_id) ON CONFLICT REPLACE
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          await db.execute('DROP TABLE IF EXISTS anime_cart');
          await db.execute('''
          CREATE TABLE anime_cart (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            anime_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            image_url TEXT NOT NULL,
            user_id INTEGER NOT NULL,
            score REAL,
            status TEXT,
            type TEXT,
            airing_start TEXT,
            source TEXT,
            genres TEXT,
            duration_minutes INTEGER,
            members INTEGER,
            favorites INTEGER,
            studios TEXT,
            episodes INTEGER,
            synopsis TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(user_id, anime_id) ON CONFLICT REPLACE
          )
        ''');
        }
      },
    );
  }


  Future<int> addUser(String username, String password) async {
    final db = await database;
    return await db.insert('users', {'username': username, 'password': password});
  }
  // Ambil data pengguna berdasarkan ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

// Ambil daftar anime favorit pengguna
  Future<List<Map<String, dynamic>>> getFavoriteAnimes(int userId) async {
    final db = await database;
    return await db.query(
      'anime_cart',
      where: 'user_id = ?',
      whereArgs: [userId],
      columns: ['title'], // Hanya ambil kolom judul
    );
  }


  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty ? results.first : null;
  }


  Future<int> addAnimeToCart(int userId, int animeId, String title, String imageUrl) async {
    final db = await database;

    // Periksa apakah anime sudah ada di cart
    final existing = await db.query(
      'anime_cart',
      where: 'anime_id = ? AND user_id = ?',
      whereArgs: [animeId, userId],
    );

    if (existing.isNotEmpty) {
      // Jika sudah ada, jangan tambahkan lagi
      return 0;
    }

    // Jika belum ada, tambahkan ke cart
    return await db.insert('anime_cart', {
      'anime_id': animeId,
      'title': title,
      'image_url': imageUrl,
      'user_id': userId,
    });
  }

  Future<void> addAnime(int userId, Anime anime) async {
    final db = await database;

    await db.insert(
      'anime_cart',
      {
        'user_id': userId,
        'anime_id': anime.id,
        'title': anime.title,
        'image_url': anime.imageUrl,
        'score': anime.score,
        'status': anime.status,
        'type': anime.type,
        'airing_start': anime.airingStart,
        'source': anime.source,
        'genres': anime.genres.join(', '),
        'duration_minutes': anime.durationMinutes,
        'members': anime.members,
        'favorites': anime.favorites,
        'studios': anime.studios.join(', '),
        'episodes': anime.episodes,
        'synopsis': anime.synopsis,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }




  Future<void> removeAnimeFromCart(int userId, int animeId) async {
    final db = await database;
    await db.delete(
      'anime_cart',
      where: 'anime_id = ? AND user_id = ?',
      whereArgs: [animeId, userId],
    );
  }



  Future<List<Map<String, dynamic>>> getCartForUser(int userId) async {
    final db = await database;
    return await db.query(
      'anime_cart',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
  Future<Map<String, dynamic>?> getAnimeInCart(int userId, int animeId) async {
    final db = await database;
    final result = await db.query(
      'anime_cart',
      where: 'anime_id = ? AND user_id = ?',
      whereArgs: [animeId, userId],
    );
    return result.isNotEmpty ? result.first : null;
  }
  Future<Map<String, dynamic>?> getAnimeById(int userId, int animeId) async {
    final db = await database;
    final result = await db.query(
      'anime_cart',
      where: 'user_id = ? AND anime_id = ?',
      whereArgs: [userId, animeId],
    );
    return result.isNotEmpty ? result.first : null;
  }
  Future<void> removeItemFromCart(int userId, int animeId) async {
    final db = await database;
    await db.delete(
      'anime_cart', // Nama tabel cart
      where: 'user_id = ? AND anime_id = ?',
      whereArgs: [userId, animeId],
    );
  }





}
