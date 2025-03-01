import 'package:flutter/material.dart';
import 'api_service.dart'; // Ujistěte se, že máte importován soubor s ApiService
import 'home_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Pokus o načtení .env souboru
    await dotenv.load(fileName: ".env");
    debugPrint('Loaded .env file.');
  } catch (e) {
    debugPrint('Failed to load .env file. Using fallback to dart-define.');
  }

  runApp(const MyApp());
}

class AppColors {
  static const veryDarkBlack = Color.fromARGB(255, 14, 14, 14);
  static const moreDarkBlack = Color.fromARGB(255, 24, 24, 24);
  static const notRealWhite = Color.fromARGB(255, 235, 235, 235);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TraqViz',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.grey[700]!,
          onSecondary: Colors.white,
          surface: AppColors.moreDarkBlack,
          onSurface: AppColors.notRealWhite,
          error: Colors.red,
          onError: Colors.black,
          outline: Colors.grey[600]!,
          shadow: Colors.grey[900]!,
        ),
        scaffoldBackgroundColor: AppColors.veryDarkBlack,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.veryDarkBlack,
          foregroundColor: Colors.white,
        ),
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    setOptimalDisplayMode();
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

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

    final List<DisplayMode> sameResolution = supported.where(
      (DisplayMode m) =>
          m.width == active.width && m.height == active.height,
    ).toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

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
      debugPrint('Začíná autentizace...');
      await ApiService.authenticate();
      debugPrint('Autentizace proběhla ústěšně');
    } catch (e) {
      debugPrint('Chyba při autentizaci: $e');
    }

    setState(() {
      _isLoading = false;
    });

    if (ApiService.accessToken != null) {
      //debugPrint("Token: \${ApiService.accessToken}");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      }
    } else {
      debugPrint('Token je null');
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
                  const SizedBox(height: 210),
                  ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TraqViz',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Objevuj své hudební statistiky.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoading)
                    const CircularProgressIndicator(
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
                duration: const Duration(milliseconds: 500),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed: () async {
                        await _authenticate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.7),
                              spreadRadius: _glowAnimation.value,
                              blurRadius: _glowAnimation.value,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: const Text(
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
