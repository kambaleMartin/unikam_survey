import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/utils/connectivity_service.dart';
import 'data/models/user_modele.dart';
import 'data/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'ui/connexion_ecran.dart';
import 'ui/ecrans/home/role_based_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = DefaultFirebaseOptions.currentPlatform;
  _validateFirebaseOptions(options);
  await Firebase.initializeApp(options: options);
  ConnectivityService().initializeSyncListener();
  runApp(const MyApp());
}

void _validateFirebaseOptions(FirebaseOptions options) {
  if ((options.projectId?.contains('YOUR_') ?? false) ||
      (options.appId?.contains('YOUR_') ?? false) ||
      (options.apiKey?.contains('YOUR_') ?? false) ||
      (options.storageBucket?.contains('YOUR_') ?? false) ||
      (options.messagingSenderId?.contains('YOUR_') ?? false)) {
    throw StateError(
      'Firebase configuration is not set. Replace the placeholder values in '
      'lib/firebase_options.dart with your Firebase project settings, or run '
      '`flutterfire configure` to generate a valid configuration.',
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<UserModel?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthRepository().verifierSessionLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIKAM Survey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155E75),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEFF3FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F3B5B),
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4F78),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF102C44),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF155E75), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF1B4F78)),
        ),
      ),
      home: FutureBuilder<UserModel?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }

          if (snapshot.hasData && snapshot.data != null) {
            return RoleBasedHomeScreen(user: snapshot.data!);
          }

          return const ConnexionScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'UNIKAM Survey',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF102C44),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36.0),
              child: Text(
                'Chargement de votre session en cours. Veuillez patienter un instant.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF516581), fontSize: 15),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFF1B4F78)),
          ],
        ),
      ),
    );
  }
}
