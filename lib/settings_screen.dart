import 'package:flutter/material.dart';
import 'organizer.dart';
import 'supabase_service.dart';
import 'historical_festivals.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            color: Color.fromARGB(255, 231, 190, 123),
            fontWeight: FontWeight.bold, // 粗體
          ), // ⭐ 字體顏色
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 40, 60, 70),
      ),
      body: ListView(
        children: [
          ListTile(
            // 🔥 新增這個選項
            leading: const Icon(Icons.history),
            title: const Text('音樂祭歷史清單'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoricalFestivalsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('主辦模式'),
            onTap: () => _openOrganizer(context),
          ),

          const Divider(),
          // ⬇️ 可在這邊新增更多設定項目
        ],
      ),
    );
  }

  Future<void> _openOrganizer(BuildContext context) async {
    final TextEditingController _passwordController = TextEditingController();
    String? errorText; // 🔥 加一個錯誤訊息變數

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => AlertDialog(
                title: const Text('請輸入主辦密碼'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '輸入密碼',
                        errorText: errorText, // 🔥 密碼錯誤時顯示紅字
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final inputPassword = _passwordController.text.trim();

                      final realPassword =
                          await SupabaseService().getOrganizerPassword();

                      if (realPassword == null) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: const Text('錯誤'),
                                  content: const Text('無法讀取主辦密碼，請稍後再試。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('確定'),
                                    ),
                                  ],
                                ),
                          );
                        }
                        return;
                      }

                      if (inputPassword == realPassword) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrganizerHomeScreen(),
                            ),
                          );
                        }
                      } else {
                        // 🔥 密碼錯誤時，清空輸入框，顯示紅字
                        setStateDialog(() {
                          _passwordController.clear();
                          errorText = '密碼錯誤，請重新輸入';
                        });
                      }
                    },
                    child: const Text('確認'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
