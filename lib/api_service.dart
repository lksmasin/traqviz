import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trackifly/main.dart';

class ApiService {
  static String get clientId => dotenv.get('CLIENT_ID');
  static String get clientSecret => dotenv.get('CLIENT_SECRET');
  static const String REDIRECT_URI = 'trackifly://callback';
  static const String SPOTIFY_API_URL_ME = 'https://api.spotify.com/v1/me';
  static const String SPOTIFY_API_URL_TRACKS = 'https://api.spotify.com/v1/me/top/tracks';
  static const String SPOTIFY_API_URL_ARTISTS = 'https://api.spotify.com/v1/me/top/artists';
  static const String SPOTIFY_API_URL_RECENTLY_PLAYED = 'https://api.spotify.com/v1/me/player/recently-played';

  static String? accessToken;
  static String? refreshToken;

  static Future<void> authenticate() async {
    final result = await FlutterWebAuth.authenticate(
      url:
          'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$REDIRECT_URI&scope=user-top-read user-read-private user-read-email user-read-recently-played',
      callbackUrlScheme: 'trackifly',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code != null) {
      await _getAccessToken(code);
    }
  }

  static Future<void> _getAccessToken(String code) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': REDIRECT_URI,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
    }
  }

  static Future<String?> fetchUserProfile() async {
    final response = await http.get(
      Uri.parse(SPOTIFY_API_URL_ME),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['images'][0]['url'];
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchTopTracks() async {
    final response = await http.get(
      Uri.parse(SPOTIFY_API_URL_TRACKS),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['items'].map((track) => {
            'name': track['name'],
            'artist': track['artists'][0]['name'],
            'image': track['album']['images'][0]['url'],
          }));
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTopArtists() async {
    final response = await http.get(
      Uri.parse(SPOTIFY_API_URL_ARTISTS),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['items'].map((artist) => {
            'name': artist['name'],
            'genres': artist['genres'],
            'image': artist['images'][0]['url'],
          }));
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchRecentPlays({int limit = 4, int days = 0}) async {
    final uri = Uri.parse(SPOTIFY_API_URL_RECENTLY_PLAYED)
        .replace(queryParameters: {'limit': limit.toString()});

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['items'].map((item) {
        final track = item['track'];
        return {
          'name': track['name'],
          'artist': track['artists'][0]['name'],
          'image': track['album']['images'][0]['url'],
          'played_at': item['played_at'],
        };
      }));
    }
    return [];
  }

  static void logout(BuildContext context) {
    accessToken = null;
    refreshToken = null;

    // Zobrazení potvrzení o odhlášení
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Byl(a) jsi úspěšně odhlášen(a).')),
    );

    // Navigace zpět na uvítací obrazovku
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
    );
  }
}
