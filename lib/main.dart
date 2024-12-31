// lib/main.dart
import 'package:blog_anon/screens/posts_me_page.dart';
import 'package:blog_anon/screens/posts_page.dart';
import 'package:blog_anon/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';
import 'navigation/bottom_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanoid2/nanoid2.dart';
import 'package:url_launcher/url_launcher.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins',
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      routes: {
        '/profile': (context) => const ProfilePage(),
        // Definisikan screen lainnya jika ada
      },
      home: const AppEntry(),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cnwfmmxuqrleotacsdci.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNud2ZtbXh1cXJsZW90YWNzZGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM4MTI1NTEsImV4cCI6MjA0OTM4ODU1MX0.RUPHXfZF5FxXAogzj3aF_ZBdTqilqw9GT-9YWJ4_ar4',
  );

  runApp(const MainApp());
}

// Halaman untuk memeriksa pertama kali penggunaan
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  _AppEntryState createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  void _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      // Arahkan ke Splash Screen pertama kali
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } else {
      // Arahkan ke halaman utama jika bukan pertama kali
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainAppHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // Loading indikator saat cek status.
      ),
    );
  }
}

// Splash Screen: Halaman pertama yang muncul ketika pertama kali membuka aplikasi
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _loadCheckboxState();
  }

  // Load checkbox state from SharedPreferences
  Future<void> _loadCheckboxState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isChecked = prefs.getBool('privacy_policy_accepted') ?? false;
    });
  }

  // Save checkbox state to SharedPreferences
  Future<void> _saveCheckboxState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_policy_accepted', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat datang di AnonTweet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isChecked = value;
                      });
                      _saveCheckboxState(value);
                    }
                  },
                ),
                GestureDetector(
                  onTap: () {
                    // Open privacy policy link
                    launchUrl(Uri.parse(
                        'https://github.com/Alfthrpy/AnonTweet/blob/master/README.md'));
                  },
                  child: const Text(
                    'I have read the Privacy Policy',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isChecked
                  ? () async {
                      // Set isFirstRun menjadi false setelah pengguna menekan "OK"
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isFirstRun', false);
                      await prefs.setString('user_id', nanoid());

                      // Pindahkan ke halaman utama
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainAppHome()),
                      );
                    }
                  : null,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

// Main app setelah Splash Screen
class MainAppHome extends StatefulWidget {
  const MainAppHome({super.key});

  @override
  _MainAppHomeState createState() => _MainAppHomeState();
}

class _MainAppHomeState extends State<MainAppHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const PostsPage(),
    const PostsMePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
