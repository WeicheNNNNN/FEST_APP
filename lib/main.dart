import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'starred_festivals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_festivals.dart';
import 'list_festivals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vrxvpmvulxhdqwubvgrn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyeHZwbXZ1bHhoZHF3dWJ2Z3JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUwNTg4MDUsImV4cCI6MjA2MDYzNDgwNX0.DmMHj4saGZR6k8zpQgqyvhG8oz3dExNGUmmdqjMZhqc',
  );
  runApp(const MusicFestApp());
}

class MusicFestApp extends StatelessWidget {
  const MusicFestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音樂祭時間表',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 64, 84, 109),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 64, 84, 109),
        ),
      ),
      home: const LaunchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _checkLastPage();
  }

  Future<void> _checkLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPage = prefs.getString('lastPage') ?? 'home'; // 預設回首頁

    if (!mounted) return;

    if (lastPage == 'starred') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StarredFestivalsScreen()),
      );
    } else if (lastPage == 'local') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocalFestivalsScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FestivalListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // 小loading
    );
  }
}
