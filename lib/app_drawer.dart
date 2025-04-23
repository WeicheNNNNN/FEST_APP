import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'list_festivals.dart';
import 'starred_festivals.dart';
import 'local_festivals.dart';
import 'custom_organizer.dart';
import 'organizer.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  const AppDrawer({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) async {
    Widget target;
    String? lastPage;
    switch (index) {
      case 0:
        target = const FestivalListScreen();
        lastPage = 'home';
        break;
      case 1:
        target = const StarredFestivalsScreen();
        lastPage = 'starred';
        break;
      case 2:
        target = const LocalFestivalsScreen();
        lastPage = 'local';
        break;
      case 3:
        target = const CustomOrganizerScreen();
        break;
      case 4:
        _showPasswordDialog(context);
        return;
      default:
        return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (lastPage != null) {
      await prefs.setString('lastPage', lastPage);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('輸入主辦密碼'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密碼'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text == '123') {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrganizerHomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        if (index != currentIndex) {
          _navigate(context, index);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: '已加星號'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '自定義清單'),
        BottomNavigationBarItem(icon: Icon(Icons.edit), label: '自定義模式'),
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts),
          label: '主辦模式',
        ),
      ],
    );
  }
}
