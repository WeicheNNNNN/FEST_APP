import 'package:flutter/material.dart';
import 'organizer.dart';

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
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController();
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('輸入密碼'),
              content: TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密碼',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text == '123') {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setState(() {
                        errorText = '密碼錯誤！';
                        controller.clear();
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

    if (success == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrganizerHomeScreen()),
      );
    }
  }
}
