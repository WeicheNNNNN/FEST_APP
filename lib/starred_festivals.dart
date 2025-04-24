import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fest_app/supabase_service.dart';
import 'package:fest_app/user_timetable.dart';

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
  }

  Future<void> _loadStarredFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final starList = prefs.getStringList('favorite_festivals') ?? [];
    final allFestivals = await SupabaseService().getFestivals();
    if (!mounted) return;
    setState(() {
      starredFestivals =
          allFestivals
              .where((fest) => starList.contains(fest['name']))
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
        title: const Text('已加星號音樂祭'),
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

      body: SafeArea(
        child:
            starredFestivals.isEmpty
                ? const Center(child: Text('目前沒有加星號的音樂祭'))
                : isGridView
                ? GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 180),

                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildFestivalTile(Map<String, dynamic> fest) {
    final imageUrl = fest['image'] ?? '';
    final festName = fest['name'] ?? '';

    if (isGridView) {
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
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/default.jpg')
                              as ImageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
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
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, // 確保透明區域也能點擊
              onTap: () => _toggleFavorite(festName),
              child: Container(
                width: 40, // 👉 增加觸控面積
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20, // ⭐ 圖案保持小
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image:
                  imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/default.jpg') as ImageProvider,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            festName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${fest['start'] ?? ''} ~ ${fest['end'] ?? ''}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(fest['city'] ?? '', style: const TextStyle(fontSize: 14)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.star),
            color: Colors.amber,
            iconSize: 30,
            onPressed: () {
              _toggleFavorite(festName);
            },
          ),
          onTap: () async {
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
        ),
      );
    }
  }
}
