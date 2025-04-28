import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fest_app/supabase_service.dart';
import 'package:fest_app/user_timetable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class StarredFestivalsScreen extends StatefulWidget {
  const StarredFestivalsScreen({super.key});

  @override
  State<StarredFestivalsScreen> createState() => _StarredFestivalsScreenState();
}

class _StarredFestivalsScreenState extends State<StarredFestivalsScreen> {
  List<Map<String, dynamic>> starredFestivals = [];
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadStarredFestivals();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? true;
    });
  }

  Future<void> _loadStarredFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final starList = prefs.getStringList('favorite_festivals') ?? [];
    final allFestivals = await SupabaseService().getFestivals();
    final today = DateTime.now();

    // 過濾掉已結束的音樂祭名稱
    final validFestivals =
        allFestivals
            .where(
              (fest) =>
                  DateTime.parse(fest['end']).isAfter(today) ||
                  DateTime.parse(fest['end']).isAtSameMomentAs(today),
            )
            .toList();

    final validStarNames = validFestivals.map((fest) => fest['name']).toSet();

    // 過濾掉過期收藏
    final filteredStarList = starList.where(validStarNames.contains).toList();

    // ⭐更新SharedPreferences，移除過期收藏
    await prefs.setStringList('favorite_festivals', filteredStarList);

    if (!mounted) return;
    setState(() {
      starredFestivals =
          validFestivals
              .where((fest) => filteredStarList.contains(fest['name']))
              .toList();
    });
  }

  Future<void> _toggleFavorite(String festName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> starList = prefs.getStringList('favorite_festivals') ?? [];

    if (starList.contains(festName)) {
      starList.remove(festName);
    } else {
      starList.add(festName);
    }
    await prefs.setStringList('favorite_festivals', starList);

    // 按下星號後重新載入，刷新清單
    _loadStarredFestivals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '收藏清單',
          style: TextStyle(
            color: Color.fromARGB(255, 231, 190, 123),
            fontWeight: FontWeight.bold, // 粗體
          ), // ⭐ 字體顏色
        ),

        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 40, 60, 70),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 231, 190, 123),
        ),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () async {
              setState(() {
                isGridView = !isGridView;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isGridView', isGridView); // 切完順便存
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
                  colors: [
                    Color.fromARGB(255, 60, 80, 90),
                    Color.fromARGB(255, 60, 80, 90),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child:
                starredFestivals.isEmpty
                    ? const Center(
                      child: Text(
                        '目前沒有收藏的音樂祭',
                        style: TextStyle(
                          color: Color.fromARGB(200, 231, 190, 123),
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
                      itemCount: starredFestivals.length,
                      itemBuilder: (context, index) {
                        final fest = starredFestivals[index];
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
                          itemCount: starredFestivals.length,
                          itemBuilder: (context, index) {
                            final fest = starredFestivals[index];
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
              HapticFeedback.lightImpact();
              final prefs = await SharedPreferences.getInstance();
              prefs.setString('lastFestival', jsonEncode(fest));
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UserTimetableScreen(
                        festival: fest,
                        sourcePage: 'starred',
                      ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                      imageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(imageUrl)
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
              behavior: HitTestBehavior.translucent,
              onTap: () => _toggleFavorite(festName),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.star, color: Colors.amber, size: 20),
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
          HapticFeedback.lightImpact();
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('lastFestival', jsonEncode(fest));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => UserTimetableScreen(
                    festival: fest,
                    sourcePage: 'starred',
                  ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image:
                        imageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(imageUrl)
                            : const AssetImage('assets/default.jpg')
                                as ImageProvider,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            festName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
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
                                fontSize: 10,
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
                IconButton(
                  icon: const Icon(Icons.star),
                  color: Colors.amber,
                  iconSize: 25,
                  onPressed: () {
                    _toggleFavorite(festName);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
