import 'package:flutter/material.dart';
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
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();

    // Animace pozadí
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _backgroundColorAnimation = ColorTween(
      begin: Colors.lightGreen.shade400,
      end: Colors.teal.shade600,
    ).animate(_animationController);
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
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
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColorAnimation.value!,
                  Colors.black,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 210),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.1 + 0.1 * _animationController.value,
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.info,
                        size: 120,
                        color: Colors.white70,
                      ),
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
                          onPressed: () => _launchURL('https://lksmasin.github.io/trackifly-web/'), //  Webová stránka
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
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Návrat na předchozí stránku
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Zpět',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}