import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fest_app/supabase_service.dart';
import 'package:fest_app/user_timetable.dart';
import 'app_drawer.dart';

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

      drawer: const AppDrawer(),
      body:
          starredFestivals.isEmpty
              ? const Center(child: Text('目前沒有加星號的音樂祭'))
              : isGridView
              ? GridView.builder(
                padding: const EdgeInsets.all(12),
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
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: starredFestivals.length,
                itemBuilder: (context, index) {
                  final fest = starredFestivals[index];
                  return _buildFestivalTile(fest);
                },
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
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: IconButton(
                padding: EdgeInsets.zero, // ⭐補上，讓 icon 小一點
                constraints: BoxConstraints(), // ⭐補上，移除預設空間
                icon: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20, // ⭐縮小
                ),
                onPressed: () {
                  _toggleFavorite(festName);
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
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
                builder: (_) => UserTimetableScreen(festival: fest),
              ),
            );
          },
        ),
      );
    }
  }
}
