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
  List<Map<String, dynamic>> _recentPlays = [];
  int _selectedIndex = 0;
  bool _showAllTracks = false;
  bool _showAllArtists = false;
  bool _showAllGenres = false;
  bool _showAllRecentPlays = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoggedIn = ApiService.accessToken != null;
    });

    if (_isLoggedIn) {
      await _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    userProfileImage = await ApiService.fetchUserProfile();
    _topTracks = await ApiService.fetchTopTracks();
    _topArtists = await ApiService.fetchTopArtists();
    _recentPlays = await ApiService.fetchRecentPlays();
    setState(() {});
  }

  Future<void> authenticate() async {
    await ApiService.authenticate().then((_) async {
      setState(() {
        _isLoggedIn = ApiService.accessToken != null;
      });

      if (_isLoggedIn) {
        await _loadUserData();
      }
    });
  }

  Future<void> logout() async {
    HapticFeedback.selectionClick();
    ApiService.logout(context);
    setState(() {
      _isLoggedIn = false;
      userProfileImage = null;
      _topTracks.clear();
      _topArtists.clear();
      _recentPlays.clear();
    });
  }

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
                      : null,
                  child: userProfileImage == null || userProfileImage!.isEmpty
                      ? Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: _isLoggedIn ? _buildSelectedTab() : WelcomeScreen(),
      bottomNavigationBar: _isLoggedIn
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home), label: 'Domů'),
                NavigationDestination(icon: Icon(Icons.equalizer), label: 'Statistiky'),
              ],
            )
          : null,
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

  Widget _buildHomeTab() {
    final topTrack = _topTracks.isNotEmpty ? _topTracks.first : null;
    final topArtist = _topArtists.isNotEmpty ? _topArtists.first : null;
    final topGenre = topArtist != null && topArtist['genres'].isNotEmpty
        ? topArtist['genres'].first
        : 'N/A';
    final recentPlay = _recentPlays.isNotEmpty ? _recentPlays.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsBlock(
            title: 'Naposledy přehraná skladba',
            content: [
              if (recentPlay != null)
                ListTile(
                  leading: recentPlay['image'] != null
                      ? Image.network(recentPlay['image'])
                      : Icon(Icons.music_note, size: 40),
                  title: Text(recentPlay['name']),
                  subtitle: Text(recentPlay['artist']),
                ),
            ],
          ),
          _buildStatsBlock(
            title: 'Nejhranější písnička',
            content: [
              if (topTrack != null)
                ListTile(
                  leading: topTrack['image'] != null
                      ? Image.network(topTrack['image'])
                      : Icon(Icons.music_note, size: 40),
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
                      : Icon(Icons.person, size: 40),
                  title: Text(topArtist['name']),
                  subtitle: Text('Žánr: $topGenre'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    int genreCounter = 1;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildExpandableStatsBlock(
            title: 'Nejhranější písničky',
            items: _topTracks,
            showAll: _showAllTracks,
            onToggle: () => setState(() => _showAllTracks = !_showAllTracks),
            itemBuilder: (track) => ListTile(
              leading: Image.network(track['image']),
              title: Text(track['name']),
              subtitle: Text(track['artist']),
            ),
          ),
          _buildExpandableStatsBlock(
            title: 'Nejhranější umělci',
            items: _topArtists,
            showAll: _showAllArtists,
            onToggle: () => setState(() => _showAllArtists = !_showAllArtists),
            itemBuilder: (artist) => ListTile(
              leading: Image.network(artist['image']),
              title: Text(artist['name']),
              subtitle: Text(artist['genres'].join(', ')),
            ),
          ),
          _buildExpandableStatsBlock(
            title: 'Nejhranější žánry',
            items: _topArtists.expand((artist) => artist['genres']).toList(),
            showAll: _showAllGenres,
            onToggle: () => setState(() => _showAllGenres = !_showAllGenres),
            itemBuilder: (genre) => ListTile(
              leading: CircleAvatar(
                child: Text('${genreCounter++}'),
              ),
              title: Text(genre),
            ),
          ),
          _buildExpandableStatsBlock(
            title: 'Historie posledních skladeb',
            items: _recentPlays,
            showAll: _showAllRecentPlays,
            onToggle: () => setState(() => _showAllRecentPlays = !_showAllRecentPlays),
            itemBuilder: (play) => ListTile(
              leading: play['image'] != null ? Image.network(play['image']) : Icon(Icons.music_note),
              title: Text(play['name']),
              subtitle: Text(play['artist']),
            ),
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

  Widget _buildExpandableStatsBlock<T>({
    required String title,
    required List<T> items,
    required bool showAll,
    required VoidCallback onToggle,
    required Widget Function(T item) itemBuilder,
  }) {
    final displayedItems = showAll ? items : items.take(4).toList();

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: Icon(showAll ? Icons.expand_less : Icons.expand_more),
                    onPressed: onToggle,
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              ...displayedItems.map(itemBuilder),
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
