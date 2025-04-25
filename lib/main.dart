import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'starred_festivals.dart';
import 'local_festivals.dart';
import 'list_festivals.dart';
import 'organizer.dart';
import 'custom_organizer.dart';
import 'user_timetable.dart';
import 'dart:ui'; // 為了 ImageFilter

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
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTimetableFestival;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialTimetableFestival,
  });
  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late int _currentIndex;
  bool _unlockedOrganizer = false;

  final List<Widget> _pages = const [
    FestivalListScreen(),
    StarredFestivalsScreen(),
    LocalFestivalsScreen(),
    CustomOrganizerScreen(),
    OrganizerHomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // 若開機指定要顯示某個音樂祭時間表
    if (widget.initialTimetableFestival != null) {
      Future.microtask(() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => UserTimetableScreen(
                  festival: widget.initialTimetableFestival!,
                ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      setState(() => _unlockedOrganizer = false);
    }
  }

  void _onTabTapped(int index) async {
    if (index == 4 && !_unlockedOrganizer) {
      final success = await _showPasswordDialog();
      if (!success) return;
      setState(() => _unlockedOrganizer = true);
    }

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<bool> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    String? errorText;

    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('輸入密碼'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          errorText: errorText,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext, rootNavigator: true).pop();
                      },
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final password = passwordController.text;
                        if (password == '123') {
                          Navigator.of(
                            dialogContext,
                            rootNavigator: true,
                          ).pop(); // 關閉對話框
                          setState(() => _unlockedOrganizer = true);
                          _onTabTapped(4);
                          setState(() => _unlockedOrganizer = false);
                        } else {
                          setState(() {
                            errorText = '密碼錯誤！';
                            passwordController.clear();
                          });
                        }
                      },
                      child: const Text('確認'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 主內容頁面
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),

          // 浮動 BottomNavigationBar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              child: BottomNavigationBar(
                backgroundColor: const Color.fromARGB(255, 22, 38, 47),
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                selectedIconTheme: const IconThemeData(size: 38),
                selectedItemColor: const Color.fromARGB(255, 231, 190, 123),
                unselectedFontSize: 12,
                unselectedIconTheme: const IconThemeData(size: 28),
                unselectedItemColor: const Color.fromARGB(150, 231, 190, 123),

                showSelectedLabels: false,
                showUnselectedLabels: false,

                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: '已加星號',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt),
                    label: '自定義清單',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.edit),
                    label: '自定義模式',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.manage_accounts),
                    label: '主辦模式',
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
