import 'package:flutter/material.dart';
import 'package:trackifly/api_service.dart';
import 'package:trackifly/setting_info_page.dart';
import 'main.dart';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
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
  Map<String, dynamic>? _currentlyPlaying;

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
    userProfileImage = (await ApiService.fetchUserProfile());
    _topTracks = await ApiService.fetchTopTracks();
    _topArtists = await ApiService.fetchTopArtists();
    _recentPlays = await ApiService.fetchRecentPlays();
    _currentlyPlaying = await ApiService.fetchCurrentlyPlaying();
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
        title: Text('TraqViz'),
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
    final currentTrack = _topTracks.isNotEmpty ? _topTracks.first : null;
    final topArtist = _topArtists.isNotEmpty ? _topArtists.first : null;
    final topGenre = topArtist != null && topArtist['genres'].isNotEmpty
        ? topArtist['genres'].first
        : 'N/A';
    final recentPlay = _recentPlays.isNotEmpty ? _recentPlays.first : null;

    // Pokud není aktuálně přehrávána skladba, zobrazíme naposledy přehrávanou
    final currentlyPlaying = _currentlyPlaying ?? recentPlay;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsBlock(
            title: 'Aktuální / poslední přehrávaná skladba',
            content: [
              if (currentlyPlaying != null)
                ListTile(
                  leading: currentlyPlaying['image'] != null
                      ? Image.network(currentlyPlaying['image'])
                      : Icon(Icons.music_note, size: 40),
                  title: Text(currentlyPlaying['name']),
                  subtitle: Text(currentlyPlaying['artist']),
                ),
            ],
          ),
          _buildStatsBlock(
            title: 'Nejhranější písnička',
            content: [
              if (currentTrack != null)
                ListTile(
                  leading: currentTrack['image'] != null
                      ? Image.network(currentTrack['image'])
                      : Icon(Icons.music_note, size: 40),
                  title: Text(currentTrack['name']),
                  subtitle: Text(currentTrack['artist']),
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
          // Přidáme sekci pro historii přehrávaných skladeb
          _buildExpandableStatsBlock(
            title: 'Historie přehrávaných skladeb',
            items: _recentPlays,
            showAll: _showAllRecentPlays,
            onToggle: () => setState(() => _showAllRecentPlays = !_showAllRecentPlays),
            itemBuilder: (track) => ListTile(
              leading: track['image'] != null
                  ? Image.network(track['image'])
                  : Icon(Icons.music_note, size: 40),
              title: Text(track['name']),
              subtitle: Text(track['artist']),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: '4 týdny'),
              Tab(text: '6 měsíců'),
              Tab(text: '12 měsíců'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStatsContent(timeRange: 'short_term'),
                _buildStatsContent(timeRange: 'medium_term'),
                _buildStatsContent(timeRange: 'long_term'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent({required String timeRange}) {
    return FutureBuilder(
      future: Future.wait([
        ApiService.fetchTopTracks(timeRange: timeRange),
        ApiService.fetchTopArtists(timeRange: timeRange),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Chyba načítání dat.'));
        }

        final data = snapshot.data as List<dynamic>;
        final topTracks = data[0] as List<Map<String, dynamic>>;
        final topArtists = data[1] as List<Map<String, dynamic>>;

        // Generating top genres from artists
        final topGenres = topArtists.expand((artist) => artist['genres']).toSet().toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildExpandableStatsBlock(
                title: 'Nejhranější písničky',
                items: topTracks,
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
                items: topArtists,
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
                items: topGenres,
                showAll: _showAllGenres,
                onToggle: () => setState(() => _showAllGenres = !_showAllGenres),
                itemBuilder: (genre) => ListTile(
                  leading: CircleAvatar(
                    child: Text('${topGenres.indexOf(genre) + 1}'),
                  ),
                  title: Text(genre),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBlock({required String title, required Iterable<Widget> content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 4.0,
        //color: Colors.white10,
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
        //color: Colors.white10,
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
    final userName = await ApiService.fetchUserName(); // Získání jména uživatele

    if (mounted) {  // Zkontrolujte, zda je widget stále "připojený"
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ahoj, $userName!'), // Zobrazení jména uživatele
                SizedBox(height: 10),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await logout();
                  Navigator.pop(context);
                },
                child: Text('Odhlásit'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
                child: Text('Nastavení'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InfoPage()),
                  );
                },
                child: Text('Informace'),
              ),
            ],
          );
        },
      );
    }
  }


}
