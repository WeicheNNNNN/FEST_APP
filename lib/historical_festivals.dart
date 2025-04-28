import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_timetable.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoricalFestivalsScreen extends StatefulWidget {
  const HistoricalFestivalsScreen({super.key});

  @override
  State<HistoricalFestivalsScreen> createState() =>
      _HistoricalFestivalsScreenState();
}

class _HistoricalFestivalsScreenState extends State<HistoricalFestivalsScreen> {
  List<Map<String, dynamic>> historicalFestivals = [];

  @override
  void initState() {
    super.initState();
    _loadHistoricalFestivals();
  }

  Future<void> _loadHistoricalFestivals() async {
    final allFestivals = await Supabase.instance.client
        .from('festivals')
        .select('id, name, start, end, stages, image, city, isPaid, map')
        .order('start', ascending: false);

    final today = DateTime.now();

    setState(() {
      historicalFestivals =
          allFestivals
              .where((fest) => DateTime.parse(fest['end']).isBefore(today))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '歷史音樂祭',
          style: TextStyle(color: Color.fromARGB(255, 231, 190, 123)),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 40, 60, 70),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 231, 190, 123),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: historicalFestivals.length,
        itemBuilder: (context, index) {
          final fest = historicalFestivals[index];
          final imageUrl = fest['image'] ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserTimetableScreen(festival: fest),
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
              child: ListTile(
                leading: ClipRRect(
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
                title: Text(
                  fest['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${fest['city']}｜${fest['start']} ~ ${fest['end']}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
