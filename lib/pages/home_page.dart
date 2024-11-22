import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/anime_model.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();

  late Future<List<Anime>> _rankingAnime;
  late Future<List<Anime>> _seasonalAnime;
  List<Anime>? _randomAnime;

  final TextEditingController _searchController = TextEditingController();
  Future<List<Anime>>? _searchResults;

  @override
  void initState() {
    super.initState();
    _rankingAnime = _apiService.fetchAnimeRanking();
    _seasonalAnime = _apiService.fetchSeasonalAnime();
    _fetchRandomAnime();
    _fetchAnimeByGenre();
  }

  Future<void> _fetchRandomAnime() async {
    final randomAnime = await _apiService.fetchRandomAnimeList(4);
    setState(() {
      _randomAnime = randomAnime;
    });
  }

  void _searchAnime() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _searchResults = _apiService.searchAnime(query);
      });
    } else {
      setState(() {
        _searchResults = null; // Reset jika pencarian kosong
      });
    }
  }
  String _selectedGenre = 'Horror'; // Default genre
  Future<List<Anime>>? _genreAnime; // Anime berdasarkan genre
  List<String> _genres = ['Action', 'Adventure', 'Comedy', 'Horror', 'Fantasy', 'Romance'];


  void _fetchAnimeByGenre() {
    setState(() {
      _genreAnime = _apiService.fetchAnimeByGenre(_selectedGenre);
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ani List'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _searchAnime(),
                decoration: InputDecoration(
                  hintText: 'Search Anime',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),


            // Search Results
            if (_searchResults != null)
              FutureBuilder<List<Anime>>(
                future: _searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No Search Results Available'));
                  }
                  // Gunakan fungsi yang sama untuk menampilkan daftar anime
                  return _buildAnimeList('Search Results', snapshot.data!);
                },
              ),


            // Ranking Anime
            FutureBuilder<List<Anime>>(
              future: _rankingAnime,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No Ranking Anime Available'));
                }
                return _buildAnimeList('Ranking Anime', snapshot.data!);
              },
            ),

            // Seasonal Anime
            FutureBuilder<List<Anime>>(
              future: _seasonalAnime,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No Seasonal Anime Available'));
                }
                return _buildAnimeList('Seasonal Anime', snapshot.data!);
              },
            ),

            // Random Anime
            _buildRandomAnimeSection(),
            // Anime Berdasarkan Genre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Anime by Genre',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedGenre,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGenre = newValue!;
                        });
                      },
                      items: _genres.map<DropdownMenuItem<String>>((String genre) {
                        return DropdownMenuItem<String>(
                          value: genre,
                          child: Text(genre),
                        );
                      }).toList(),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _fetchAnimeByGenre,
                    ),
                  ],
                ),
                FutureBuilder<List<Anime>>(
                  future: _genreAnime,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No Anime Available for Genre: $_selectedGenre'));
                    }
                    return _buildAnimeList('', snapshot.data!);
                  },
                ),

              ],
            ),

          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
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

  Widget _buildAnimeList(String title, List<Anime> animeList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(anime: anime),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 100,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          anime.imageUrl,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildRandomAnimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Random Anime',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchRandomAnime,
            ),
          ],
        ),
        _randomAnime == null
            ? Center(child: CircularProgressIndicator())
            : _randomAnime!.isEmpty
            ? Center(child: Text('No Random Anime Available'))
            : GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _randomAnime!.length,
          itemBuilder: (context, index) {
            final anime = _randomAnime![index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(anime: anime),
                  ),
                );
              },
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      anime.imageUrl,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
