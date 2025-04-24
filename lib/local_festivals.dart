import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_timetable.dart';

class LocalFestivalsScreen extends StatefulWidget {
  const LocalFestivalsScreen({super.key});

  @override
  State<LocalFestivalsScreen> createState() => _LocalFestivalsScreenState();
}

class _LocalFestivalsScreenState extends State<LocalFestivalsScreen> {
  List<Map<String, dynamic>> localFestivals = [];
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadLocalFestivals();
  }

  Future<void> _loadLocalFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final localDataString = prefs.getString('local_festivals');
    if (localDataString != null) {
      final decoded =
          (jsonDecode(localDataString) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      setState(() {
        localFestivals = decoded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定義清單'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(180, 30, 65, 96),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          // 🔹 背景漸層
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFF1E4160)],
                ),
              ),
            ),
          ),
          SafeArea(
            child:
                localFestivals.isEmpty
                    ? const Center(child: Text('尚未建立任何自定義音樂祭'))
                    : isGridView
                    ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 180),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: localFestivals.length,
                      itemBuilder: (context, index) {
                        final fest = localFestivals[index];
                        return _buildFestivalTile(fest);
                      },
                    )
                    : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 80.0,
                        ), // ⬅️ 為 BottomNavigationBar 預留空間
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: localFestivals.length,
                          itemBuilder: (context, index) {
                            final fest = localFestivals[index];
                            return _buildFestivalTile(fest);
                          },
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFestivalTile(Map<String, dynamic> fest) {
    final imageUrl = fest['image'] ?? '';
    final festName = fest['name'] ?? '';

    if (isGridView) {
      // --- 格子模式 ---
      return Stack(
        children: [
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.setString('lastFestival', jsonEncode(fest));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UserTimetableScreen(
                        festival: fest,
                        sourcePage: 'local',
                      ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                      imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/default.jpg')
                              as ImageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 6,
                    offset: const Offset(5, 7),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        festName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fest['start'] ?? ''} ~ ${fest['end'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fest['city'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ⭐ 左上角標籤：「付費」或「免費」
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (fest['isPaid'] == true)
                        ? Colors.orange.shade900
                        : Colors.green.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (fest['isPaid'] == true) ? '付費' : '免費',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // --- 清單模式 ---
      return GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('lastFestival', jsonEncode(fest));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      UserTimetableScreen(festival: fest, sourcePage: 'local'),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 6,
                offset: const Offset(5, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左邊縮圖
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image:
                        imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage('assets/default.jpg')
                                as ImageProvider,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // 中間文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min, // ⭐讓Row大小剛好，不要撐開
                        children: [
                          Text(
                            fest['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6), // 小小間距
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (fest['isPaid'] == true)
                                      ? Colors.orange.shade900
                                      : Colors.green.shade900,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (fest['isPaid'] == true) ? '付費' : '免費',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10, // ⭐這裡字體要小一點才不會太擠
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        '${fest['city'] ?? ''}｜${fest['start'] ?? ''} ~ ${fest['end'] ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
