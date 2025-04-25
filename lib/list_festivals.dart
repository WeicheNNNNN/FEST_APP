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
  bool showSearchBar = false;

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
        title: const Text(
          'Festigo',
          style: TextStyle(
            color: Color.fromARGB(255, 231, 190, 123),
            fontWeight: FontWeight.bold, // 粗體
          ), // ⭐ 字體顏色
        ),

        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 22, 38, 47),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 231, 190, 123),
        ),
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              showSearchBar = !showSearchBar;
              if (!showSearchBar) {
                query = '';
                searchController.clear();
              }
            });
          },
        ),
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
          // 背景層（放漸層或圖片）
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(220, 22, 38, 47),
                  Color.fromARGB(255, 22, 38, 47),
                ],
              ),
            ),
          ),

          // 前景內容
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshFestivals,
                  child:
                      filteredFestivals.isEmpty
                          ? const Center(
                            child: Text(
                              '找不到符合的音樂祭',
                              style: TextStyle(
                                color: Color.fromARGB(255, 231, 190, 123),
                              ), // ⭐ 字體顏色
                            ),
                          )
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
                            itemCount: filteredFestivals.length,
                            itemBuilder: (context, index) {
                              final fest = filteredFestivals[index];
                              return _buildFestivalTile(fest);
                            },
                          )
                          : SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 80.0,
                              ), // ⬅️ 為 BottomNavigationBar 預留空間
                              child: ListView.builder(
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
                ),
              ),
            ],
          ),

          // === 搜尋欄動畫區塊 ===
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: AnimatedScale(
              scale: showSearchBar ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: showSearchBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !showSearchBar,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '搜尋音樂祭名稱或地點',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon:
                            query.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      query = '';
                                      searchController.clear();
                                    });
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: Colors.white, // ✅ 實心白底
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black), // 使用者輸入文字顏色
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                  ),
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
                  builder:
                      (_) => UserTimetableScreen(
                        festival: fest,
                        sourcePage: 'list',
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
                width: 40, // 🔺拉大觸控面積
                height: 40,
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
                        ? Color.fromARGB(223, 243, 105, 76)
                        : Color.fromARGB(255, 40, 140, 112),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (fest['isPaid'] == true) ? '付' : '免',
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
              builder:
                  (_) =>
                      UserTimetableScreen(festival: fest, sourcePage: 'list'),
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
                                      ? Color.fromARGB(223, 243, 105, 76)
                                      : Color.fromARGB(255, 40, 140, 112),
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
