import 'package:flutter/material.dart';
import '../models/clip_model.dart';
import '../data/clips_data.dart';
import 'clip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLevel = 'Tümü';
  int _xp = 120;
  int _streak = 3;
  final Set<String> _completedIds = {};

  List<ClipItem> get _filteredClips {
    if (_selectedLevel == 'Tümü') return sampleClips;
    return sampleClips.where((c) => c.level == _selectedLevel).toList();
  }

  void _onClipCompleted(String id) {
    setState(() {
      _xp += 50;
      if (!_completedIds.contains(id)) {
        _completedIds.add(id);
        _streak++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['Tümü', 'A2', 'B1', 'B2'];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_filter, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CineLingo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Dizi ve Filmlerle İngilizce',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Streak Counter
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_streak',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFBBF24)),
                ),
              ],
            ),
          ),
          // XP Counter
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10, right: 12, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFA855F7), size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_xp XP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFC084FC)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF312E81).withOpacity(0.6),
                  const Color(0xFF1E1B4B).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.headphones, color: Color(0xFF818CF8), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Videolar İndirilmez, Canlı Akışla Dinlenir',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sahneleri izle, dinleme testini çöz ve karakterlerin ne dediğini anla!',
                        style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Level Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: levels.map((lvl) {
                final isSel = _selectedLevel == lvl;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lvl),
                    selected: isSel,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLevel = lvl;
                      });
                    },
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF1F2937),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF374151),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Clips List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredClips.length,
              itemBuilder: (context, index) {
                final clip = _filteredClips[index];
                final isCompleted = _completedIds.contains(clip.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981).withOpacity(0.5)
                          : const Color(0xFF1F2937),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClipDetailScreen(
                              clip: clip,
                              onClipCompleted: () => _onClipCompleted(clip.id),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Preview
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 100,
                                    height: 75,
                                    color: Colors.black45,
                                    child: Image.network(
                                      'https://img.youtube.com/vi/${clip.youtubeId}/hqdefault.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.movie, color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${clip.endSeconds - clip.startSeconds} sn',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          clip.series,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF818CF8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF374151),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          clip.level,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isCompleted)
                                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    clip.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${clip.questions.length} Soru • ${clip.accent} Aksanı',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
