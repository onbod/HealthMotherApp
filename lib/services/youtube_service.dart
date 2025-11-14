import 'package:http/http.dart' as http;
import 'dart:convert';

class Video {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;

  Video({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id']['videoId'],
      title: json['snippet']['title'],
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'],
      channelTitle: json['snippet']['channelTitle'],
    );
  }
}

class YouTubeService {
  // YouTube Data API key - get from Google Cloud Platform console
  // Make sure to enable the "YouTube Data API v3" for your project.
  static const _apiKey =
      'AIzaSyDZ-Xfj8HUOruFfHbCwHyqnZdc2qRKyrG4'; // IMPORTANT: REPLACE WITH YOUR API KEY
  static const _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<List<Video>> getPregnancyVideos({int? week, String? trimester}) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY') {
      throw Exception('You must provide a valid YouTube Data API key.');
    }
    String searchQuery = 'pregnancy health tips';

    final url = Uri.parse(
      '$_baseUrl/search?part=snippet&q=$searchQuery&type=video&maxResults=10&key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['items'] == null || data['items'].isEmpty) {
        throw Exception('No videos found for the search query.');
      }
      // Only include items with a videoId
      final filtered =
          (data['items'] as List)
              .where(
                (item) =>
                    item['id'] != null &&
                    item['id']['kind'] == 'youtube#video' &&
                    item['id']['videoId'] != null,
              )
              .toList();
      if (filtered.isEmpty) {
        throw Exception('No valid videos found in the API response.');
      }
      return filtered.map((item) => Video.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load videos: ${response.body}');
    }
  }
}
