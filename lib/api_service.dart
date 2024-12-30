import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trackifly/main.dart';
import 'package:flutter/foundation.dart' as Foundation;  // Pro detekci platformy

class ApiService {
  static String get clientId => dotenv.get('CLIENT_ID');
  static String get clientSecret => dotenv.get('CLIENT_SECRET');
  static const String REDIRECT_URI = 'trackifly://callback';
  static const String SPOTIFY_API_URL_ME = 'https://api.spotify.com/v1/me';
  static const String SPOTIFY_API_URL_TRACKS = 'https://api.spotify.com/v1/me/top/tracks';
  static const String SPOTIFY_API_URL_ARTISTS = 'https://api.spotify.com/v1/me/top/artists';
  static const String SPOTIFY_API_URL_RECENTLY_PLAYED = 'https://api.spotify.com/v1/me/player/recently-played';
  static const String SPOTIFY_API_URL_CURRENTLY_PLAYING = 'https://api.spotify.com/v1/me/player/currently-playing'; // Nový endpoint pro aktuální skladbu

  static String? accessToken;
  static String? refreshToken;

  static Future<void> authenticate() async {
    String redirectUri;

    // Pokud jsme na webu, použijeme URL pro webovou autentizaci
    if (Foundation.kIsWeb) {
      redirectUri = 'http://0.0.0.0:8000/auth.html';  // URL na auth.html pro web
    } else {
      redirectUri = 'trackifly://callback';  // URI pro nativní platformy (Android/iOS)
    }

    final result = await FlutterWebAuth2.authenticate(
      url:
          'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=user-top-read user-read-private user-read-email user-read-recently-played user-read-playback-state',
      callbackUrlScheme: Foundation.kIsWeb ? 'http://0.0.0.0:8000/auth.html' : 'trackifly',  // Webová callback URL nebo nativní URI schéma
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

  static Future<List<Map<String, dynamic>>> fetchRecentPlays({int limit = 30, int days = 0}) async {
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

  static Future<Map<String, dynamic>?> fetchCurrentlyPlaying() async {
    final response = await http.get(
      Uri.parse(SPOTIFY_API_URL_CURRENTLY_PLAYING),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Ověření, že data obsahují položku 'item', která je skladba
      if (data == null || data['item'] == null) {
        // Pokud není žádná skladba přehrávána, získáme naposledy přehrávanou skladbu
        return await fetchLastPlayedTrack();
      }

      return {
        'name': data['item']['name'],
        'artist': data['item']['artists'][0]['name'],
        'image': data['item']['album']['images'][0]['url'],
      };
    } else {
      print('Error: ${response.statusCode} - ${response.body}');  // Logování chyby
    }

    return null;  // Pokud API nevrátí platná data
  }

  static Future<Map<String, dynamic>?> fetchLastPlayedTrack() async {
    final response = await http.get(
      Uri.parse(SPOTIFY_API_URL_RECENTLY_PLAYED),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['items'] != null && data['items'].isNotEmpty) {
        final track = data['items'][0]['track'];
        return {
          'name': track['name'],
          'artist': track['artists'][0]['name'],
          'image': track['album']['images'][0]['url'],
        };
      }
    } else {
      print('Error: ${response.statusCode} - ${response.body}');  // Logování chyby
    }

    return null;  // Pokud není žádná poslední skladba
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
