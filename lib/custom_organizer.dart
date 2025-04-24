// custom_organizer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'organizer.dart';

class CustomOrganizerScreen extends StatefulWidget {
  const CustomOrganizerScreen({super.key});

  @override
  State<CustomOrganizerScreen> createState() => _CustomOrganizerScreenState();
}

class _CustomOrganizerScreenState extends State<CustomOrganizerScreen> {
  List<Map<String, dynamic>> festivals = [];

  @override
  void initState() {
    super.initState();
    _loadFestivals();
  }

  Future<void> _loadFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString('local_festivals');
    if (localData != null) {
      final List<dynamic> decoded = jsonDecode(localData);
      setState(() {
        festivals = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveFestivals() async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned =
        festivals
            .map(
              (fest) => {
                'id': (fest['id'] ?? '').toString(),
                'name': fest['name'] ?? '',
                'start': fest['start'] ?? '',
                'end': fest['end'] ?? '',
                'stages': (fest['stages'] ?? []) is List ? fest['stages'] : [],
                'image': fest['image'] ?? '',
                'city': fest['city'] ?? '',
                'isPaid': fest['isPaid'] ?? false,
              },
            )
            .toList();
    prefs.setString('local_festivals', jsonEncode(cleaned));
  }

  void _addFestival(Map<String, dynamic> festival) {
    setState(() {
      festivals.add({
        ...festival,
        'city': festival['city'] ?? '',
        'isPaid': festival['isPaid'] ?? false,
      });
      festivals.sort((a, b) => a['start'].compareTo(b['start']));
    });
    _saveFestivals();
  }

  void _openFestivalDetail(int index) async {
    final fest = festivals[index];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FestivalManageScreen(
              festival: fest,
              onUpdate: (updated) {
                setState(
                  () =>
                      festivals[index] = {
                        'id': updated['id'],
                        'name': updated['name'] ?? '',
                        'start': updated['start'] ?? '',
                        'end': updated['end'] ?? '',
                        'stages': updated['stages'] ?? [],
                        'image': updated['image'] ?? '',
                        'city': updated['city'] ?? '',
                        'isPaid': updated['isPaid'] ?? false,
                      },
                );
                _saveFestivals();
              },
            ),
      ),
    );

    if (result != null) {
      setState(
        () =>
            festivals[index] = {
              'id': result['id'],
              'name': result['name'] ?? '',
              'start': result['start'] ?? '',
              'end': result['end'] ?? '',
              'stages': result['stages'] ?? [],
              'image': result['image'] ?? '',
              'city': result['city'] ?? '',
              'isPaid': result['isPaid'] ?? false,
            },
      );
      _saveFestivals();
    }
  }

  void _showAddFestivalDialog() async {
    String name = '';
    DateTime? startDate;
    DateTime? endDate;
    String city = '';
    bool isPaid = false;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('新增音樂祭'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(labelText: '音樂祭名稱'),
                          onChanged: (value) => name = value,
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: '縣市'),
                          value: city.isEmpty ? null : city,
                          items:
                              [
                                    '基隆市',
                                    '台北市',
                                    '新北市',
                                    '桃園市',
                                    '新竹市',
                                    '新竹縣',
                                    '苗栗縣',
                                    '台中市',
                                    '彰化縣',
                                    '南投縣',
                                    '雲林縣',
                                    '嘉義市',
                                    '嘉義縣',
                                    '台南市',
                                    '高雄市',
                                    '屏東縣',
                                    '台東縣',
                                    '花蓮縣',
                                    '宜蘭縣',
                                    '澎湖縣',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              city = value ?? '';
                            });
                          },
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('是否為付費活動'),
                            Switch(
                              value: isPaid,
                              onChanged: (value) {
                                setState(() {
                                  isPaid = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('起始日：'),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => startDate = picked);
                                }
                              },
                              child: Text(
                                startDate == null
                                    ? '選擇'
                                    : '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('結束日：'),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: startDate ?? DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => endDate = picked);
                                }
                              },
                              child: Text(
                                endDate == null
                                    ? '選擇'
                                    : '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (name.isNotEmpty &&
                            startDate != null &&
                            endDate != null) {
                          _addFestival({
                            'name': name,
                            'start':
                                '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}',
                            'end':
                                '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}',
                            'stages': [],
                            'city': city,
                            'isPaid': isPaid,
                            'image': '',
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('新增'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定義模式'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(200, 96, 125, 139),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 70.0,
          right: 20.0,
        ), // ⬅️ 避開 BottomNavigationBar
        child: FloatingActionButton(
          onPressed: _showAddFestivalDialog, // ← 每頁這個可以換成自己頁面要用的
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          child: const Icon(Icons.add),
        ),
      ),

      body: SafeArea(
        child:
            festivals.isEmpty
                ? const Center(child: Text('尚未建立任何音樂祭'))
                : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 200),
                  itemCount: festivals.length,
                  itemBuilder: (context, index) {
                    final festival = festivals[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text(festival['name'] ?? ''),
                        subtitle: Text(
                          '${festival['city']}｜${festival['start']} ~ ${festival['end']}',
                        ),
                        onTap: () => _openFestivalDetail(index),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final nameController = TextEditingController(
                                  text: festival['name'],
                                );
                                DateTime? start = DateTime.tryParse(
                                  festival['start'],
                                );
                                DateTime? end = DateTime.tryParse(
                                  festival['end'],
                                );
                                bool isPaid =
                                    festival['isPaid'] ?? false; // ⭐ 這行
                                String city = festival['city'] ?? '';

                                final updated = await showDialog<
                                  Map<String, dynamic>
                                >(
                                  context: context,
                                  builder:
                                      (_) => StatefulBuilder(
                                        builder:
                                            (context, setState) => AlertDialog(
                                              title: const Text('編輯音樂祭'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          nameController,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: '音樂祭名稱',
                                                          ),
                                                    ),
                                                    DropdownButtonFormField<
                                                      String
                                                    >(
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: '縣市',
                                                          ),
                                                      value:
                                                          city.isEmpty
                                                              ? null
                                                              : city,
                                                      items:
                                                          [
                                                                '基隆市',
                                                                '台北市',
                                                                '新北市',
                                                                '桃園市',
                                                                '新竹市',
                                                                '新竹縣',
                                                                '苗栗縣',
                                                                '台中市',
                                                                '彰化縣',
                                                                '南投縣',
                                                                '雲林縣',
                                                                '嘉義市',
                                                                '嘉義縣',
                                                                '台南市',
                                                                '高雄市',
                                                                '屏東縣',
                                                                '台東縣',
                                                                '花蓮縣',
                                                                '宜蘭縣',
                                                                '澎湖縣',
                                                              ]
                                                              .map(
                                                                (c) =>
                                                                    DropdownMenuItem(
                                                                      value: c,
                                                                      child:
                                                                          Text(
                                                                            c,
                                                                          ),
                                                                    ),
                                                              )
                                                              .toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          city = value ?? '';
                                                        });
                                                      },
                                                    ),

                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text('是否為付費活動'),
                                                        Switch(
                                                          value: isPaid,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              isPaid = value;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),

                                                    Row(
                                                      children: [
                                                        const Text('起始日：'),
                                                        TextButton(
                                                          onPressed: () async {
                                                            final picked =
                                                                await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      start ??
                                                                      DateTime.now(),
                                                                  firstDate:
                                                                      DateTime(
                                                                        2020,
                                                                      ),
                                                                  lastDate:
                                                                      DateTime(
                                                                        2030,
                                                                      ),
                                                                );
                                                            if (picked !=
                                                                null) {
                                                              setState(
                                                                () =>
                                                                    start =
                                                                        picked,
                                                              );
                                                            }
                                                          },
                                                          child: Text(
                                                            start == null
                                                                ? '選擇'
                                                                : '${start!.year}-${start!.month.toString().padLeft(2, '0')}-${start!.day.toString().padLeft(2, '0')}',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        const Text('結束日：'),
                                                        TextButton(
                                                          onPressed: () async {
                                                            final picked =
                                                                await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      end ??
                                                                      DateTime.now(),
                                                                  firstDate:
                                                                      DateTime(
                                                                        2020,
                                                                      ),
                                                                  lastDate:
                                                                      DateTime(
                                                                        2030,
                                                                      ),
                                                                );
                                                            if (picked !=
                                                                null) {
                                                              setState(
                                                                () =>
                                                                    end =
                                                                        picked,
                                                              );
                                                            }
                                                          },
                                                          child: Text(
                                                            end == null
                                                                ? '選擇'
                                                                : '${end!.year}-${end!.month.toString().padLeft(2, '0')}-${end!.day.toString().padLeft(2, '0')}',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('取消'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (nameController
                                                            .text
                                                            .isNotEmpty &&
                                                        start != null &&
                                                        end != null) {
                                                      Navigator.pop(context, {
                                                        'name':
                                                            nameController.text,
                                                        'start':
                                                            '${start!.year}-${start!.month.toString().padLeft(2, '0')}-${start!.day.toString().padLeft(2, '0')}',
                                                        'end':
                                                            '${end!.year}-${end!.month.toString().padLeft(2, '0')}-${end!.day.toString().padLeft(2, '0')}',
                                                        'stages':
                                                            festival['stages'] ??
                                                            [],
                                                        'city': city, // ⭐補這個
                                                        'isPaid':
                                                            isPaid, // ⭐補這個
                                                      });
                                                    }
                                                  },
                                                  child: const Text('儲存'),
                                                ),
                                              ],
                                            ),
                                      ),
                                );

                                if (updated != null) {
                                  final updatedFestival =
                                      {
                                        ...festivals[index],
                                        ...updated,
                                        'id': festivals[index]['id'], // 保留原本的id
                                      }.cast<String, dynamic>();

                                  setState(() {
                                    festivals[index] = updatedFestival;
                                  });

                                  _saveFestivals(); // 再存回SharedPreferences
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: const Text('刪除確認'),
                                        content: Text(
                                          '確定要刪除「${festival['name']}」嗎？',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('取消'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('刪除'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  setState(() => festivals.removeAt(index));
                                  _saveFestivals();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
