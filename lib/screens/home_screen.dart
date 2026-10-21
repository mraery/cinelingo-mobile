import 'package:flutter/material.dart';
import '../data/clips_data.dart';
import '../models/clip_model.dart';
import '../services/user_store.dart';
import '../widgets/monetization_dialogs.dart';
import 'clip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLevel = 'Tümü';
  String _selectedAccessFilter = 'Tümü'; // 'Tümü', 'Ücretsiz', 'VIP'
  String _searchQuery = '';
  final List<String> _levels = ['Tümü', 'A1', 'A2', 'B1', 'B2', 'C1'];

  List<ClipItem> get _filteredClips {
    return sampleClips.where((c) {
      if (_selectedLevel != 'Tümü' && c.level != _selectedLevel) return false;
      if (_selectedAccessFilter == 'Ücretsiz' && c.isVip) return false;
      if (_selectedAccessFilter == 'VIP' && !c.isVip) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = c.title.toLowerCase().contains(q) ||
            c.series.toLowerCase().contains(q) ||
            c.genre.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void _handleClipTap(ClipItem clip) {
    final store = UserStore.instance;
    if (!store.isVip && !store.isCheatUnlocked && store.hearts <= 0) {
      OutOfHeartsDialog.show(context);
      return;
    }

    if (!store.isClipAccessible(clip)) {
      VipClipUnlockSheet.show(
        context,
        clip: clip,
        onUnlocked: () {
          if (!mounted) return;
          _openClipScreen(clip);
        },
      );
      return;
    }

    _openClipScreen(clip);
  }

  void _openClipScreen(ClipItem clip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClipDetailScreen(clip: clip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserStore.instance,
      builder: (context, _) {
        final store = UserStore.instance;
        final clips = _filteredClips;

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111827),
            elevation: 0,
            titleSpacing: 14,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'CineLingo',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.4),
                  ),
                ),
                if (store.isCheatUnlocked) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚡ KAGAN',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.amber),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // Can Göstergesi
              InkWell(
                onTap: () => CineLingoProSheet.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Row(
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        (store.isVip || store.isCheatUnlocked) ? '∞' : '${store.hearts}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              // Elmas Göstergesi
              InkWell(
                onTap: () => CineLingoProSheet.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${store.gems}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                      ),
                    ],
                  ),
                ),
              ),
              // Promosyon Kodu Butonu
              IconButton(
                tooltip: 'Promosyon Kodu',
                onPressed: () => CineLingoPromoDialog.show(context),
                icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFA5B4FC), size: 22),
              ),
              // PRO / Mağaza Butonu
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => CineLingoProSheet.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text(
                          store.isVip ? 'VIP' : 'PRO',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst PRO & Ödüllü Reklam Banner Alanı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monetization Banner (Ücretsiz kullanıcılara PRO & Reklam İzle Kazan kartı)
                    if (!store.isVip)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF312E81), Color(0xFF4C1D95)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            const Text('🎬', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ücretsiz Elmas Kazan veya PRO\'ya Geç!',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '26+ film sahnesi • Reklam izle +40 💎 kazan',
                                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                RewardedAdDialog.show(
                                  context,
                                  rewardTitle: '+40 💎 Elmas & +1 ❤️ Can',
                                  onRewardEarned: () {
                                    store.addGems(40);
                                    store.gainHearts(1);
                                  },
                                );
                              },
                              child: const Text('+40 💎 İzle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // Arama Çubuğu
                    SizedBox(
                      height: 42,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Dizi, film veya konu ara (Friends, Matrix, Sherlock...)',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF818CF8), size: 19),
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF374151)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF374151)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Seviye ve Erişim Filtreleri
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._levels.map((lvl) {
                            final isSelected = _selectedLevel == lvl;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(lvl),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedLevel = lvl),
                                selectedColor: const Color(0xFF6366F1),
                                backgroundColor: const Color(0xFF1F2937),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 6),
                          ...['Ücretsiz', 'VIP'].map((filter) {
                            final isSelected = _selectedAccessFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(filter == 'VIP' ? '👑 VIP' : '🔓 Ücretsiz'),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedAccessFilter = isSelected ? 'Tümü' : filter;
                                  });
                                },
                                selectedColor: const Color(0xFFD97706),
                                backgroundColor: const Color(0xFF1F2937),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.amber[300],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sahne Sayısı vePromosyon Kodu Kısa Yolu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎬 Toplam ${clips.length} Dizi & Film Sahnesi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    InkWell(
                      onTap: () => CineLingoPromoDialog.show(context),
                      child: const Text(
                        '🎁 Promosyon Kodu Gir',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                      ),
                    ),
                  ],
                ),
              ),

              // Sahne Kartları Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: clips.length,
                  itemBuilder: (context, index) {
                    final clip = clips[index];
                    return _buildClipCard(clip, store);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClipCard(ClipItem clip, UserStore store) {
    final isAccessible = store.isClipAccessible(clip);
    final isCompleted = store.isClipCompleted(clip.id);

    return GestureDetector(
      onTap: () => _handleClipTap(clip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                : (clip.isVip && !isAccessible)
                    ? Colors.amber.withValues(alpha: 0.45)
                    : const Color(0xFF1F2937),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getLevelColor(clip.level).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getLevelColor(clip.level)),
                        ),
                        child: Text(
                          clip.level,
                          style: TextStyle(
                            color: _getLevelColor(clip.level),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (clip.isVip)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAccessible
                                ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                : Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAccessible ? '👑 VIP AÇIK' : '🔒 VIP SAHNE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isAccessible ? const Color(0xFF34D399) : Colors.amber,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ÜCRETSİZ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${clip.accent} • ${clip.genre}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                clip.series.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                clip.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                clip.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.quiz_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${clip.questions.length} Soru', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(width: 14),
                  Icon(Icons.subtitles_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${clip.transcript.length} Replik', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (clip.isVip && !isAccessible)
                          ? const Color(0xFFD97706)
                          : const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (clip.isVip && !isAccessible) ? Icons.lock_open_rounded : Icons.play_arrow_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (clip.isVip && !isAccessible)
                              ? 'Kilidi Aç'
                              : (isCompleted ? 'Tekrar İzle ✅' : 'İzle & Çöz'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return const Color(0xFF34D399);
      case 'A2':
        return const Color(0xFF10B981);
      case 'B1':
        return const Color(0xFF3B82F6);
      case 'B2':
        return const Color(0xFFF59E0B);
      case 'C1':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
