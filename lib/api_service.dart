import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get clientId => dotenv.get('CLIENT_ID');
  static String get clientSecret => dotenv.get('CLIENT_SECRET');
  static const String REDIRECT_URI = 'trackifly://callback';  // Zůstává pevně nastavené
  static const String SPOTIFY_API_URL_ME = 'https://api.spotify.com/v1/me';  // Zůstává pevně nastavené
  static const String SPOTIFY_API_URL_TRACKS = 'https://api.spotify.com/v1/me/top/tracks';  // Zůstává pevně nastavené
  static const String SPOTIFY_API_URL_ARTISTS = 'https://api.spotify.com/v1/me/top/artists';  // Zůstává pevně nastavené

  static String? accessToken;
  static String? refreshToken;

  static Future<void> authenticate() async {
    final result = await FlutterWebAuth.authenticate(
      url:
          'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$REDIRECT_URI&scope=user-top-read user-read-private user-read-email',
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
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
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

  static Future<String?> fetchLastPlayedTrack() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/recently-played'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'].isNotEmpty) {
        var lastTrack = data['items'][0];
        return lastTrack['track']['name'] + ' - ' + lastTrack['track']['artists'][0]['name'];
      }
    }
    return null;
  }

  static void logout() {
    accessToken = null;
    refreshToken = null;
  }
}
