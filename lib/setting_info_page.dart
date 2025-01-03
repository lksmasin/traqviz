import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  InfoPageState createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Animace pro glow efekt
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Nepodařilo se otevřít URL: $url';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 150),
                  // Bez animace pro ikonu
                  Icon(
                    Icons.info,
                    size: 120,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Trackifly',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Informace o aplikaci.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Trackifly je aplikace pro analýzu a sledování tvých hudebních statistik a preferencí ze Spotify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Všechny obrázky jsou chráněny autorským právem příslušných vlastníků autorských práv.\nTato aplikace není nijak spojena se Spotify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Odkazy:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.language, color: Colors.white),
                        onPressed: () => _launchURL('https://lksmasin.github.io/trackifly-web/'), // Webová stránka
                      ),
                      IconButton(
                        icon: Icon(Icons.code, color: Colors.white),
                        onPressed: () => _launchURL('https://github.com/lksmasin/trackifly'), // GitHub
                      ),
                      IconButton(
                        icon: Icon(Icons.android, color: Colors.white),
                        onPressed: () => _launchURL('https://play.google.com/store/apps/details?id=io.github.lksmasin.trackifly'), // Google Play Store
                      ),
                    ],
                  ),
                  SizedBox(height: 140),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 500),
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return ElevatedButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.pop(context); // Návrat na předchozí stránku
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding:
                                EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Zaoblené rohy
                            ),
                            elevation: 10, // Zvýšení efektu glow
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  spreadRadius: _glowAnimation.value, // Nastavení šířky glow efektu
                                  blurRadius: _glowAnimation.value,   // Nastavení rozmazání glow efektu
                                  offset: Offset(0, 0), // Střední pozice
                                ),
                              ],
                            ),
                            child: Text(
                              'Zpět',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
