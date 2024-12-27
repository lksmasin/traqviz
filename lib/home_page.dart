import 'package:flutter/material.dart';
import 'package:trackifly/api_service.dart';
import 'main.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;
  String? userProfileImage;
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _topArtists = [];
  String? _lastPlayedTrack;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Zkontrolujeme, jestli je uživatel přihlášen, pokud ne, přesměrujeme na uvítací obrazovku
  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoggedIn = ApiService.accessToken != null;
    });

    if (_isLoggedIn) {
      await _loadUserData();  // Načteme data po přihlášení
    }
  }

  // Funkce pro načtení uživatelských dat
  Future<void> _loadUserData() async {
    userProfileImage = await ApiService.fetchUserProfile();
    _topTracks = await ApiService.fetchTopTracks();
    _topArtists = await ApiService.fetchTopArtists();
    _lastPlayedTrack = await ApiService.fetchLastPlayedTrack();
    setState(() {});
  }

  // Funkce pro přihlášení
  Future<void> authenticate() async {
    await ApiService.authenticate().then((_) async {
      setState(() {
        _isLoggedIn = ApiService.accessToken != null;
      });

      if (_isLoggedIn) {
        await _loadUserData();  // Načteme data po přihlášení
      }
    });
  }

  // Funkce pro odhlášení
  Future<void> logout() async {
    ApiService.logout(context);
    setState(() {
      _isLoggedIn = false;
      userProfileImage = null;
      _topTracks.clear();
      _topArtists.clear();
      _lastPlayedTrack = null;
    });
  }

  // Funkce pro přepínání mezi taby
  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trackifly'),
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => _showProfileMenu(),
                child: CircleAvatar(
                  backgroundImage: userProfileImage != null && userProfileImage!.isNotEmpty
                      ? NetworkImage(userProfileImage!)
                      : null, // Použijeme NetworkImage pokud je obrázek k dispozici
                  child: userProfileImage == null || userProfileImage!.isEmpty
                      ? Icon(Icons.person, size: 40) // Pokud není obrázek, zobrazí ikonu
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: _isLoggedIn ? _buildSelectedTab() : WelcomeScreen(), // Pokud není přihlášen, zobrazí se uvítací obrazovka
      bottomNavigationBar: _isLoggedIn
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home), label: 'Domů'),
                NavigationDestination(icon: Icon(Icons.equalizer), label: 'Statistiky'),
              ],
            )
          : null, // Navigační lišta se zobrazuje pouze po přihlášení
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildStatsTab();
      default:
        return Center(child: Text('Neznámá karta'));
    }
  }

  // Opravený kód pro buildStatsTab
  Widget _buildStatsTab() {
    int genreCounter = 1;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildStatsBlock(
          title: 'Nejhranější písničky',
          content: _topTracks.map((track) => ListTile(
                leading: Image.network(track['image']),
                title: Text(track['name']),
                subtitle: Text(track['artist']),
              )).toList(), // Přidání toList pro správné vykreslení
        ),
        _buildStatsBlock(
          title: 'Nejhranější umělci',
          content: _topArtists.map((artist) => ListTile(
                leading: Image.network(artist['image']),
                title: Text(artist['name']),
                subtitle: Text(artist['genres'].join(', ')),
              )).toList(), // Přidání toList pro správné vykreslení
        ),
        _buildStatsBlock(
          title: 'Nejhranější žánry',
          content: _topArtists
              .expand((artist) => artist['genres'])
              .toSet()
              .map((genre) => ListTile(
                    leading: CircleAvatar(
                      child: Text('${genreCounter++}'),
                    ),
                    title: Text(genre),
                  )).toList(), // Přidání toList pro správné vykreslení
        ),
      ],
    );
  }

  // Opravené použití Image.network s výchozím obrázkem při null hodnotě
  // Opravené použití Icon místo Image.network s výchozí hodnotou
  Widget _buildHomeTab() {
    final topTrack = _topTracks.isNotEmpty ? _topTracks.first : null;
    final topArtist = _topArtists.isNotEmpty ? _topArtists.first : null;
    final topGenre = topArtist != null && topArtist['genres'].isNotEmpty
        ? topArtist['genres'].first
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsBlock(
            title: 'Nejhranější písnička',
            content: [
              if (topTrack != null)
                ListTile(
                  leading: topTrack['image'] != null
                      ? Image.network(topTrack['image'])
                      : Icon(Icons.music_note, size: 40), // Ikona místo obrázku
                  title: Text(topTrack['name']),
                  subtitle: Text(topTrack['artist']),
                ),
            ],
          ),
          _buildStatsBlock(
            title: 'Nejhranější umělec',
            content: [
              if (topArtist != null)
                ListTile(
                  leading: topArtist['image'] != null
                      ? Image.network(topArtist['image'])
                      : Icon(Icons.person, size: 40), // Ikona místo obrázku
                  title: Text(topArtist['name']),
                  subtitle: Text('Žánr: $topGenre'),
                ),
            ],
          ),
          _buildStatsBlock(
            title: 'Naposledy hraná písnička',
            content: [
              if (_lastPlayedTrack != null)
                ListTile(
                  title: Text(_lastPlayedTrack!),
                ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildStatsBlock({required String title, required Iterable<Widget> content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16.0),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileMenu() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Profile Menu'),
          actions: [
            TextButton(
              onPressed: () async {
                await logout();
                Navigator.pop(context);
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
