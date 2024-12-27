import 'package:flutter/material.dart';
import 'api_service.dart'; // Ujistěte se, že máte importován soubor s ApiService
import 'home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: "lib/.env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackifly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  // Funkce pro přihlášení přes Spotify
  Future<void> _authenticate() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });
    await ApiService.authenticate();
    setState(() {
      _isLoading = false;
    });
    if (ApiService.accessToken != null) {
      // Přesměrování nebo pokračování v aplikaci po úspěšném přihlášení
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    }
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Ikona aplikace
                  Icon(Icons.music_note, size: 100, color: Colors.amber),
                  SizedBox(height: 20),
                  // Název aplikace
                  Text(
                    'Trackifly',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Popis aplikace
                  Text(
                    'Objevujte své hudební preference a sledujte oblíbené skladby a umělce na Spotify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 30),
                  // Spinner pro načítání, pokud je potřeba
                  if (_isLoading)
                    CircularProgressIndicator(
                      color: Colors.amber, // Material 3 spinner
                    ),
                ],
              ),
            ),
          ),
          // Tlačítko na spodní část obrazovky s odsazením
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0), // Odsazení od spodního okraje
              child: _isLoading
                  ? Container() // Pokud je loading, tlačítko se nezobrazí
                  : ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        'Přihlásit se přes Spotify',
                        style: TextStyle(
                          color: Colors.black, // Nastavíme barvu textu na černou
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
