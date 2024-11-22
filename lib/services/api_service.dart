import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_model.dart';

class ApiService {
  static const String _baseUrl = "https://api.jikan.moe/v4";

  Future<List<Anime>> fetchAnimeRanking() async {
    final response = await http.get(Uri.parse('https://api.jikan.moe/v4/top/anime'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> animeList = data['data'];

      return animeList.map((anime) => Anime.fromJson(anime)).toList(); // Konversi ke Anime
    } else {
      throw Exception('Failed to load anime ranking');
    }
  }
  final Map<String, int> _genreIds = {
  'Action': 1,
  'Adventure': 2,
  'Comedy': 4,
  'Horror': 14,
  'Fantasy': 10,
  'Romance': 22,
  };

  Future<List<Anime>> fetchAnimeByGenre(String genre) async {
    final genreId = _genreIds[genre]; // Ambil ID genre berdasarkan nama
    if (genreId == null) throw Exception('Invalid genre selected');

    final response = await http.get(
      Uri.parse('https://api.jikan.moe/v4/anime?genres=$genreId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return List<Anime>.from(data.map((anime) => Anime.fromJson(anime)));
    } else {
      throw Exception('Failed to load anime by genre');
    }
  }


  Future<List<Anime>> fetchSeasonalAnime() async {
    final response = await http.get(Uri.parse('$_baseUrl/seasons/now'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> animeList = data['data'];

      return animeList.map((anime) => Anime.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to load seasonal anime');
    }
  }

  Future<List<Anime>> fetchRandomAnimeList(int count) async {
    List<Anime> animeList = [];
    for (int i = 0; i < count; i++) {
      final response = await http.get(Uri.parse('$_baseUrl/random/anime'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        animeList.add(Anime.fromJson(data['data']));
      }
    }
    return animeList;
  }

  Future<List<Anime>> searchAnime(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/anime?q=$query'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> animeList = data['data'];
      return animeList.map((anime) => Anime.fromJson(anime)).toList();
    } else {
      throw Exception('Failed to search anime');
    }
  }

}
