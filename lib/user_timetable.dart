import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'dart:async';

class UserTimetableScreen extends StatefulWidget {
  final Map<String, dynamic> festival;
  final String? sourcePage; // 新增來源頁面參數

  const UserTimetableScreen({
    super.key,
    required this.festival,
    this.sourcePage,
  });

  @override
  State<UserTimetableScreen> createState() => _UserTimetableScreenState();
}

class _UserTimetableScreenState extends State<UserTimetableScreen> {
  static const double cellHeight = 30;
  static const double timeWidth = 50;
  static const double stageWidth = 150;

  Timer? _timer;
  DateTime now = DateTime.now();
  late ScrollController timeAxisController; // 左邊時間軸專用
  late ScrollController contentVerticalController; // 右邊節目專用
  late ScrollController horizontalController; // 左右滾用

  Set<String> favorites = {};

  @override
  void dispose() {
    _timer?.cancel(); // ⭐新增
    timeAxisController.dispose();
    contentVerticalController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    timeAxisController = ScrollController();
    contentVerticalController = ScrollController();
    horizontalController = ScrollController();

    // ⭐讓時間軸跟著節目同步上下滾動
    contentVerticalController.addListener(() {
      if (timeAxisController.hasClients &&
          contentVerticalController.hasClients) {
        timeAxisController.jumpTo(contentVerticalController.offset);
      }
    });

    // ⭐新增：啟動 timer 每30秒更新時間
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_${widget.festival['name']}';
    final favList = prefs.getStringList(key) ?? [];
    setState(() {
      favorites = favList.toSet();
    });
  }

  Future<void> _toggleFavorite(String favKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_${widget.festival['name']}';
    setState(() {
      if (favorites.contains(favKey)) {
        favorites.remove(favKey);
      } else {
        favorites.add(favKey);
      }
      prefs.setStringList(key, favorites.toList());
    });
  }

  List<String> getTimeSlots() {
    final List<String> slots = [];
    DateTime time = DateTime(2023, 1, 1, 10, 0);
    while (time.hour < 23 || (time.hour == 23 && time.minute <= 30)) {
      slots.add(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
      time = time.add(const Duration(minutes: 10));
    }
    return slots;
  }

  List<Map<String, String>> getDateTabs(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    List<Map<String, String>> tabs = [];
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      tabs.add({
        'label': '${current.month}/${current.day}',
        'key':
            '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}',
      });
      current = current.add(const Duration(days: 1));
    }
    return tabs;
  }

  int timeToIndex(String time) {
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return ((hour - 10) * 6 + (minute ~/ 10)).clamp(
      0,
      81,
    ); // 81 = (23:30 - 10:00) / 10min
  }

  double _calculateNowOffset() {
    final nowTime = now;
    int hour = nowTime.hour;
    int minute = nowTime.minute;

    int minutesFromStart = (hour - 10) * 60 + minute;

    if (minutesFromStart < 0 || minutesFromStart > (13 * 60 + 30)) return -1000;
    return minutesFromStart / 10 * cellHeight;
  }

  @override
  Widget build(BuildContext context) {
    final stages = List<Map<String, dynamic>>.from(
      widget.festival['stages'] ?? [],
    );

    final timeSlots = getTimeSlots();
    final tabInfo = getDateTabs(
      widget.festival['start'],
      widget.festival['end'],
    );

    return DefaultTabController(
      length: tabInfo.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('lastFestival'); // 清除記錄

              int initialIndex = 0;
              switch (widget.sourcePage) {
                case 'starred':
                  initialIndex = 1;
                  break;
                case 'local':
                  initialIndex = 2;
                  break;
                case 'list':
                default:
                  initialIndex = 0;
              }

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MainNavigationScreen(initialIndex: initialIndex),
                ),
                (route) => false,
              );
            },
          ),

          title: Text(
            '${widget.festival['name']} 時間表',
            style: TextStyle(
              color: Color.fromARGB(255, 231, 190, 123),
              fontWeight: FontWeight.bold, // 粗體
            ), // ⭐ 字體顏色
          ),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 231, 190, 123),
          ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 30, 46, 56),
          bottom: TabBar(
            isScrollable: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 30),
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color.fromARGB(150, 255, 255, 255),
            ),
            indicatorColor: Color.fromARGB(255, 255, 255, 255), // 線的顏色
            indicatorWeight: 4.0, // 線的粗細
            indicatorPadding: EdgeInsets.symmetric(horizontal: 10), // 左右內縮
            tabs: tabInfo.map((d) => Tab(text: d['label'])).toList(),
          ),
        ),
        body: TabBarView(
          children:
              tabInfo.map((tab) {
                final dateKey = tab['key']!;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        // 左邊：時間軸，單獨上下滾動
                        SingleChildScrollView(
                          controller: timeAxisController,
                          scrollDirection: Axis.vertical,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(top: cellHeight * 1.5),
                            child: Stack(
                              children: [
                                // ⭐額外補一個空白半格
                                Column(
                                  children: [
                                    ...List.generate(
                                      timeSlots.length,
                                      (i) => Container(
                                        width: timeWidth,
                                        height: cellHeight,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          timeSlots[i],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color.fromARGB(
                                              255,
                                              40,
                                              60,
                                              70,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: cellHeight * 4), // 額外空白
                                  ],
                                ),

                                // ⭐新增一個小紅色現在時間字
                                Positioned(
                                  right: 2,
                                  top:
                                      _calculateNowOffset() +
                                      cellHeight * 0.5 -
                                      9, // ⭐跟右邊紅線對齊
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width: timeWidth,
                                  height: cellHeight * 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 右邊：舞台欄 + 節目區域，一起左右滾動
                        Expanded(
                          child: SingleChildScrollView(
                            controller: horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 舞台欄 (固定在上方，不捲動)
                                Row(
                                  children:
                                      stages.map((stage) {
                                        final color = Color(
                                          int.parse(
                                            (stage['color'] ?? '#3F51B5')
                                                .replaceFirst('#', '0xff'),
                                          ),
                                        );
                                        return Container(
                                          width: stageWidth,
                                          height: cellHeight * 1.5,
                                          alignment: Alignment.center,
                                          color: color,
                                          child: Text(
                                            stage['stage'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),

                                // 節目表 (上下滾動、背景線 + 節目區)
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: contentVerticalController,
                                    scrollDirection: Axis.vertical,
                                    child: Stack(
                                      children: [
                                        // 這邊保留你的背景線 + 節目列表的原本邏輯
                                        Positioned(
                                          left: 0,
                                          top: cellHeight * 0.5,
                                          child: Column(
                                            children: List.generate(
                                              timeSlots.length,
                                              (i) {
                                                final isHour = timeSlots[i]
                                                    .endsWith(":00");
                                                return Container(
                                                  width:
                                                      stageWidth *
                                                      stages.length,
                                                  height: cellHeight,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                        color:
                                                            isHour
                                                                ? Color.fromARGB(
                                                                  255,
                                                                  40,
                                                                  60,
                                                                  70,
                                                                )
                                                                : Color.fromARGB(
                                                                  100,
                                                                  40,
                                                                  60,
                                                                  70,
                                                                ),
                                                        width:
                                                            isHour ? 1.2 : 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // ⭐新增現在時間紅線
                                        Positioned(
                                          left: 0,
                                          top:
                                              _calculateNowOffset() +
                                              cellHeight * 0.5, // ⭐加半格，對齊背景線
                                          child: Container(
                                            width: stageWidth * stages.length,
                                            height: 3,
                                            color: Colors.red,
                                          ),
                                        ),

                                        // 節目表格（Row包每個舞台）
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children:
                                              stages.map((stage) {
                                                final raw =
                                                    stage['performances'];
                                                final performanceMap =
                                                    raw is String
                                                        ? jsonDecode(raw)
                                                        : Map<
                                                          String,
                                                          dynamic
                                                        >.from(raw ?? {});
                                                final dayPerformances =
                                                    performanceMap[dateKey]
                                                            is List
                                                        ? List<
                                                          Map<String, dynamic>
                                                        >.from(
                                                          performanceMap[dateKey],
                                                        )
                                                        : [];

                                                List<Widget> stageCells =
                                                    List.generate(
                                                      timeSlots.length,
                                                      (i) => Container(
                                                        width: stageWidth,
                                                        height: cellHeight,
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                    );

                                                // 畫節目區塊
                                                for (final p
                                                    in dayPerformances) {
                                                  try {
                                                    final band =
                                                        p['band'] ?? '';
                                                    final time = p['time'];
                                                    final parts = time.split(
                                                      " - ",
                                                    );
                                                    if (parts.length == 2) {
                                                      final startIdx =
                                                          timeToIndex(parts[0]);
                                                      final endIdx =
                                                          timeToIndex(parts[1]);
                                                      final span = (endIdx -
                                                              startIdx)
                                                          .clamp(
                                                            1,
                                                            timeSlots.length -
                                                                startIdx,
                                                          );
                                                      final key =
                                                          '${widget.festival['name']}|$dateKey|${stage['stage']}|$band|$time';
                                                      final isFavorite =
                                                          favorites.contains(
                                                            key,
                                                          );

                                                      Color stageColor;
                                                      try {
                                                        stageColor = Color(
                                                          int.parse(
                                                            (stage['color'] ??
                                                                    '#3F51B5')
                                                                .replaceFirst(
                                                                  '#',
                                                                  '0xff',
                                                                ),
                                                          ),
                                                        );
                                                      } catch (_) {
                                                        stageColor =
                                                            Colors.indigo;
                                                      }

                                                      stageCells[startIdx] = MouseRegion(
                                                        cursor:
                                                            SystemMouseCursors
                                                                .click,
                                                        child: GestureDetector(
                                                          onTap:
                                                              () =>
                                                                  _toggleFavorite(
                                                                    key,
                                                                  ),
                                                          child: AnimatedContainer(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      200,
                                                                ),
                                                            width: stageWidth,
                                                            height:
                                                                cellHeight *
                                                                span,
                                                            alignment:
                                                                Alignment
                                                                    .center,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  isFavorite
                                                                      ? stageColor
                                                                      : Colors
                                                                          .grey
                                                                          .shade300,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade400,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              band,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    isFavorite
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );

                                                      for (
                                                        int i = 1;
                                                        i < span;
                                                        i++
                                                      ) {
                                                        if (startIdx + i <
                                                            stageCells.length) {
                                                          stageCells[startIdx +
                                                                  i] =
                                                              const SizedBox.shrink();
                                                        }
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print('⚠️ 節目錯誤: $e');
                                                  }
                                                }

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: cellHeight * 0.5,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      ...stageCells,
                                                      // ⭐ 加一段留白區域
                                                      const SizedBox(
                                                        height: 100,
                                                      ), // 這邊你可以調整高度
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FestivalMapScreen(festival: widget.festival),
              ),
            );
          },
          backgroundColor: Color.fromARGB(255, 40, 60, 70),
          child: const Icon(Icons.map, color: Colors.white),
        ),
      ),
    );
  }
}

class FestivalListDialog extends StatefulWidget {
  final List<Map<String, dynamic>> festivals;

  const FestivalListDialog(this.festivals, {super.key});

  @override
  State<FestivalListDialog> createState() => _FestivalListDialogState();
}

class _FestivalListDialogState extends State<FestivalListDialog> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filteredFestivals =
        widget.festivals
            .where(
              (fest) =>
                  (fest['name'] ?? '').toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (fest['city'] ?? '').toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();

    return AlertDialog(
      title: const Text('選擇音樂祭'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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

            const SizedBox(height: 12),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 80.0,
                  ), // ⬅️ 為 BottomNavigationBar 預留空間
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredFestivals.length,
                    itemBuilder: (context, index) {
                      final fest = filteredFestivals[index];
                      return ListTile(
                        title: Text(fest['name'] ?? ''),
                        subtitle: Text(fest['city'] ?? ''),
                        onTap: () {
                          Navigator.pop(context, fest['name']);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class FestivalMapScreen extends StatelessWidget {
  final Map<String, dynamic> festival;

  const FestivalMapScreen({super.key, required this.festival});

  Widget _buildMapContent() {
    if (festival['map'] != null && festival['map'].toString().isNotEmpty) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Container(
          color: Color.fromARGB(255, 60, 80, 90),
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            festival['map'],
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            },
          ),
        ),
      );
    } else {
      return const Center(
        child: Text('此音樂祭尚未上傳地圖', style: TextStyle(fontSize: 18)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${festival['name']} 地圖',
          style: const TextStyle(
            color: Color.fromARGB(255, 231, 190, 123),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 40, 60, 70),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 231, 190, 123),
        ),
      ),
      body: _buildMapContent(), // ⭐這裡叫剛剛那個 function
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: const Color.fromARGB(255, 40, 60, 70),
        child: const Icon(Icons.list, color: Colors.white),
      ),
    );
  }
}
