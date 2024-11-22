class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final double score;
  final String status;
  final String type;
  final String airingStart;
  final String source;
  final List<String> genres;
  final int durationMinutes;
  final int members;
  final int favorites;
  final List<String> studios;
  final int? episodes; // Nullable
  final String? synopsis; // Nullable

  Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.status,
    required this.type,
    required this.airingStart,
    required this.source,
    required this.genres,
    required this.durationMinutes,
    required this.members,
    required this.favorites,
    required this.studios,
    this.episodes, // Nullable
    this.synopsis, // Nullable
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['mal_id'],
      title: json['title'] ?? 'No Title',
      imageUrl: json['images']['jpg']['image_url'] ?? '',
      synopsis: json['synopsis'] ?? 'No synopsis available',
      score: (json['score'] != null) ? json['score'].toDouble() : 0.0,
      episodes: json['episodes'] ?? 0,
      status: json['status'] ?? 'Unknown',
      type: json['type'] ?? 'Unknown',
      airingStart: json['aired']['string'] ?? 'N/A',
      source: json['source'] ?? 'Original',
      genres: (json['genres'] as List<dynamic>?)
          ?.map((genre) => genre['name'] as String)
          .toList() ??
          [],
      durationMinutes: _parseDuration(json['duration']),
      members: json['members'] ?? 0,
      favorites: json['favorites'] ?? 0,
      studios: (json['studios'] as List<dynamic>?)
          ?.map((studio) => studio['name'] as String)
          .toList() ??
          [],
    );
  }


  static int _parseDuration(String? duration) {
    if (duration == null) return 0;
    final regex = RegExp(r'(\d+)\s*min');
    final match = regex.firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'mal_id': id,
      'title': title,
      'image_url': imageUrl,
      'synopsis': synopsis,
      'score': score,
      'episodes': episodes,
      'status': status,
      'type': type,
      'aired_start': airingStart,
      'source': source,
      'genres': genres,
      'duration_minutes': durationMinutes,
      'members': members,
      'favorites': favorites,
      'studios': studios,
    };
  }

  double get averageTimePerEpisode {
    return (episodes! > 0) ? durationMinutes.toDouble() : 0.0;
  }
}
