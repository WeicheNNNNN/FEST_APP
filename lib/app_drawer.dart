import 'package:flutter/material.dart';
import 'organizer.dart';
import 'custom_organizer.dart';
import 'starred_festivals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_festivals.dart';
import 'list_festivals.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(100, 96, 125, 139)),
            child: Text(
              '功能選單',
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
          ),
          // --- 上半部：使用者常用功能 ---
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('首頁'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('lastPage', 'home');
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const FestivalListScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('已加星號'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('lastPage', 'starred');
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const StarredFestivalsScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('自定義清單'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('lastPage', 'local');
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LocalFestivalsScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          const Divider(), // ⭐ 分隔線
          // --- 下半部：管理功能 ---
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('自定義模式'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomOrganizerScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('主辦模式'),
            onTap: () async {
              final TextEditingController passwordController =
                  TextEditingController();
              String? errorText;

              await showDialog(
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
                              Navigator.of(
                                dialogContext,
                                rootNavigator: true,
                              ).pop();
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
                                ).pop();
                                Navigator.pop(context);
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const OrganizerHomeScreen(),
                                      ),
                                    );
                                  },
                                );
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
              );
            },
          ),
        ],
      ),
    );
  }
}
