import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trackifly/main.dart';
import 'package:flutter/foundation.dart' as foundation;

class ApiService {
  static String get clientSecret =>
      dotenv.isInitialized && dotenv.env['CLIENT_SECRET'] != null
          ? dotenv.get('CLIENT_SECRET')
          : const String.fromEnvironment('CLIENT_SECRET', defaultValue: '');
  static const String clientId = 'a97e9776d53f41cdbe9c6e61f97c6e80';
  static const String redirectUri = 'trackifly://callback';
  static const String spotifyApiUrlMe = 'https://api.spotify.com/v1/me';
  static const String spotifyApiUrlTracks = 'https://api.spotify.com/v1/me/top/tracks';
  static const String spotifyApiUrlArtists = 'https://api.spotify.com/v1/me/top/artists';
  static const String spotifyApiUrlRecentlyPlayed = 'https://api.spotify.com/v1/me/player/recently-played';
  static const String spotifyApiUrlCurrentlyPlaying = 'https://api.spotify.com/v1/me/player/currently-playing';

  static String? accessToken;
  static String? refreshToken;

  static Future<void> authenticate() async {
    String usedRedirectUri;
    String callbackUrlScheme;

    if (foundation.kIsWeb) {
      usedRedirectUri = 'https://lksmasin.github.io/trackifly/auth.html';
      callbackUrlScheme = 'http';
    } else {
      usedRedirectUri = 'trackifly://callback';
      callbackUrlScheme = 'trackifly';
    }

    final result = await FlutterWebAuth2.authenticate(
      url:
          'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$usedRedirectUri&scope=user-top-read user-read-private user-read-email user-read-recently-played user-read-playback-state',
      callbackUrlScheme: callbackUrlScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code != null) {
      await _getAccessToken(code);
    }
  }

  static Future<void> _getAccessToken(String code) async {
    String usedRedirectUri;
    if (foundation.kIsWeb) {
      usedRedirectUri = 'https://lksmasin.github.io/trackifly/auth.html';
    } else {
      usedRedirectUri = 'trackifly://callback';
    }

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': usedRedirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
    } else {
      debugPrint('Error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String?> fetchUserProfile() async {
    final response = await http.get(
      Uri.parse(spotifyApiUrlMe),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['images'][0]['url'];
    }
    return null;
  }

  static Future<String?> fetchUserName() async {
    final response = await http.get(
      Uri.parse(spotifyApiUrlMe),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchTopTracks({String timeRange = 'short_term'}) async {
    final uri = Uri.parse(spotifyApiUrlTracks).replace(queryParameters: {'time_range': timeRange});

    final response = await http.get(
      uri,
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

  static Future<List<Map<String, dynamic>>> fetchTopArtists({String timeRange = 'short_term'}) async {
    final uri = Uri.parse(spotifyApiUrlArtists).replace(queryParameters: {'time_range': timeRange});

    final response = await http.get(
      uri,
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

  static Future<List<Map<String, dynamic>>> fetchRecentPlays({int limit = 30}) async {
    final uri = Uri.parse(spotifyApiUrlRecentlyPlayed)
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
      Uri.parse(spotifyApiUrlCurrentlyPlaying),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data == null || data['item'] == null) {
        return await fetchLastPlayedTrack();
      }

      return {
        'name': data['item']['name'],
        'artist': data['item']['artists'][0]['name'],
        'image': data['item']['album']['images'][0]['url'],
      };
    } else {
      debugPrint('Error: ${response.statusCode} - ${response.body}');
    }

    return null;
  }

  static Future<Map<String, dynamic>?> fetchLastPlayedTrack() async {
    final response = await http.get(
      Uri.parse(spotifyApiUrlRecentlyPlayed),
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
      debugPrint('Error: ${response.statusCode} - ${response.body}');
    }

    return null;
  }

  static void logout(BuildContext context) {
    accessToken = null;
    refreshToken = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Byl(a) jsi úspěšně odhlášen(a).')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
    );
  }
}
