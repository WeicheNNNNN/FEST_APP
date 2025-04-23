import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

import 'user_timetable.dart';

class FestivalListScreen extends StatefulWidget {
  const FestivalListScreen({super.key});

  @override
  State<FestivalListScreen> createState() => _FestivalListScreenState();
}

class _FestivalListScreenState extends State<FestivalListScreen> {
  List<Map<String, dynamic>> festivals = [];
  String query = '';
  bool isGridView = true;
  Set<String> favoriteFestivals = {}; // 存收藏的音樂祭名稱
  bool showFavoritesOnly = false; // ⭐是否只看收藏
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _loadFavorites(); // ⭐ 加這個
    _loadLastFestival();
    _loadFestivals();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_festivals') ?? [];
    if (mounted) {
      setState(() {
        favoriteFestivals = favList.toSet();
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorite_festivals', favoriteFestivals.toList());
  }

  Future<void> _loadLastFestival() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFestivalString = prefs.getString('lastFestival');
    if (lastFestivalString != null) {
      final lastFestival =
          jsonDecode(lastFestivalString) as Map<String, dynamic>;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserTimetableScreen(festival: lastFestival),
          ),
        );
      }
    }
  }

  Future<void> _loadFestivals() async {
    final cloudData = await SupabaseService().getFestivals();
    if (mounted) {
      setState(() {
        festivals = cloudData;
        festivals.sort((a, b) => a['start'].compareTo(b['start']));
      });
    }
  }

  Future<void> _refreshFestivals() async {
    final cloudData = await SupabaseService().getFestivals();
    if (mounted) {
      setState(() {
        festivals = cloudData;
        festivals.sort((a, b) => a['start'].compareTo(b['start']));
      });
    }
  }

  List<Map<String, dynamic>> get filteredFestivals {
    final list =
        festivals.where((fest) {
          final name = fest['name'] ?? '';
          final city = fest['city'] ?? '';
          final matchQuery =
              name.toLowerCase().contains(query.toLowerCase()) ||
              city.toLowerCase().contains(query.toLowerCase());
          final isStarred = favoriteFestivals.contains(name);
          return matchQuery && (!showFavoritesOnly || isStarred);
        }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FEST_App'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(100, 96, 125, 139),
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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController, // ⭐這行加上
              decoration: InputDecoration(
                hintText: '搜尋音樂祭名稱或地點',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              query = '';
                              searchController.clear(); // ⭐這行加上，清掉TextField
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFestivals,
              child:
                  filteredFestivals.isEmpty
                      ? const Center(child: Text('找不到符合的音樂祭'))
                      : isGridView
                      ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: filteredFestivals.length,
                        itemBuilder: (context, index) {
                          final fest = filteredFestivals[index];
                          return _buildFestivalTile(fest);
                        },
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          100,
                        ), // ⭐ 底部多 100px 空間

                        itemCount: filteredFestivals.length,
                        itemBuilder: (context, index) {
                          final fest = filteredFestivals[index];
                          return _buildFestivalTile(fest);
                        },
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

    final bool isStarred = favoriteFestivals.contains(festName); // ⭐改這個名字

    if (isGridView) {
      // --- 格子模式 ---
      return Stack(
        children: [
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.setString('lastFestival', jsonEncode(fest));
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserTimetableScreen(festival: fest),
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
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.4 * 255).round()),
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
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, // 讓整個容器都能點擊
              onTap: () {
                setState(() {
                  if (isStarred) {
                    favoriteFestivals.remove(festName);
                  } else {
                    favoriteFestivals.add(festName);
                  }
                });
                _saveFavorites();
              },
              child: Container(
                width: 48, // 🔺拉大觸控面積
                height: 48,
                alignment: Alignment.center, // 圖示保持置中
                child: Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? Colors.amber : Colors.white,
                  size: 20, // ⭐圖示維持小
                ),
              ),
            ),
          ),

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
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
              builder: (_) => UserTimetableScreen(festival: fest),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
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

                // 右邊星星
                IconButton(
                  iconSize: 25, // ⭐這裡可以自己調
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isStarred) {
                        favoriteFestivals.remove(festName);
                      } else {
                        favoriteFestivals.add(festName);
                      }
                    });
                    _saveFavorites();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose(); // 🔥這行很重要
    super.dispose();
  }
}
