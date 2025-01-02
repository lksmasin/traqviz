import 'package:flutter/material.dart';
import 'api_service.dart'; // Ujistěte se, že máte importován soubor s ApiService
import 'home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ujistěte se, že se widgety správně inicializují
  await dotenv.load(fileName: "lib/.env");
  runApp(MyApp());
}

class AppColors {
  static const veryDarkBlack = Color.fromARGB(255, 14, 14, 14);
  static const moreDarkBlack = Color.fromARGB(255, 24, 24, 24);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackifly',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark, // Tmavý režim
          primary: Colors.white, // Hlavní barva (např. pro AppBar)
          onPrimary: Colors.black, // Text na hlavní barvě
          secondary: Colors.grey[700]!, // Sekundární barva
          onSecondary: Colors.white, // Text na sekundární barvě
          surface: AppColors.moreDarkBlack, // Karty
          onSurface: Colors.white, // Text na povrchové barvě
          error: Colors.red, // Chybová barva
          onError: Colors.black,
          outline: Colors.grey[600]!,
          shadow: Colors.grey[900]!,
        ),
        scaffoldBackgroundColor: AppColors.veryDarkBlack, // Čistě černé pozadí aplikace

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.veryDarkBlack, // Černý AppBar
          foregroundColor: Colors.white, // Text v AppBaru
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white10, // Barva pozadí
          indicatorColor: Colors.white12, // Barva indikátoru pro vybranou položku
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(color: Colors.white, fontSize: 12),
          ),
          iconTheme: WidgetStateProperty.all(
            IconThemeData(color: Colors.white),
          ),
        ),
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    setOptimalDisplayMode(); // Zavolání metody pro nastavení optimálního režimu zobrazení
    super.initState();

    // Animace pozadí
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    // Animace pro glow efekt
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    // Filtrujeme režimy se stejným rozlišením, jako má aktivní režim
    final List<DisplayMode> sameResolution = supported.where(
      (DisplayMode m) =>
          m.width == active.width && m.height == active.height,
    ).toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate)); // Seřadíme podle obnovovací frekvence

    // Vybereme režim s nejvyšší obnovovací frekvencí
    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

    // Nastavíme preferovaný režim
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      print('Začíná autentizace...');
      await ApiService.authenticate();
      print('Autentizace proběhla úspěšně');
    } catch (e) {
      print('Chyba při autentizaci: $e');
    }

    setState(() {
      _isLoading = false;
    });

    if (ApiService.accessToken != null) {
      print("Token: ${ApiService.accessToken}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } else {
      print('Token je null');
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
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 210),
                  ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png', // Cesta k logu
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover, // Přizpůsobení obrázku do kruhu
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
                    'Objevuj své hudební statistiky.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 40),
                  if (_isLoading)
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.0 : 1.0,
                duration: Duration(milliseconds: 500),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed: () async {
                        await _authenticate(); // Spustí autentizaci
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
                          'Přihlásit se přes Spotify',
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
            ),
          ),
        ],
      ),
    );
  }
}
