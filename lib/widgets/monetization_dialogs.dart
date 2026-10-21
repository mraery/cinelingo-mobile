import 'dart:async';
import 'package:flutter/material.dart';
import '../models/clip_model.dart';
import '../services/user_store.dart';

/// 1. PROMOSYON KODU DİYALOĞU (Sadece "kagan" yazılınca hileler aktif olur)
class CineLingoPromoDialog extends StatefulWidget {
  const CineLingoPromoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CineLingoPromoDialog(),
    );
  }

  @override
  State<CineLingoPromoDialog> createState() => _CineLingoPromoDialogState();
}

class _CineLingoPromoDialogState extends State<CineLingoPromoDialog> {
  final TextEditingController _controller = TextEditingController();
  PromoResponse? _response;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    final res = UserStore.instance.applyPromoCode(text);
    setState(() {
      _response = res;
      if (preset != null) {
        _controller.text = preset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF374151), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF818CF8), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promosyon Kodu',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hediye veya kampanya kodunuzu girin',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Promosyon kodunu yazın...',
                  hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFF818CF8), size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
                  ),
                ),
                onSubmitted: (_) => _apply(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Aktif Kampanya: ', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                  InkWell(
                    onTap: () => _apply('SINEMA2026'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '🎁 SINEMA2026 (+75 💎)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA5B4FC)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_response != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _response!.success
                        ? (_response!.isCheat
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                            : const Color(0xFF10B981).withValues(alpha: 0.15))
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _response!.success
                          ? (_response!.isCheat ? const Color(0xFFA855F7) : const Color(0xFF10B981))
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Text(
                    _response!.message,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _apply(),
                child: const Text('KODU UYGULA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. ÖDÜLLÜ VİDEO REKLAM DİYALOĞU (Rewarded Video Ad - Para Kazanma Modülü)
class RewardedAdDialog extends StatefulWidget {
  final String rewardTitle;
  final VoidCallback onRewardEarned;

  const RewardedAdDialog({
    super.key,
    required this.rewardTitle,
    required this.onRewardEarned,
  });

  static Future<bool> show(
    BuildContext context, {
    required String rewardTitle,
    required VoidCallback onRewardEarned,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardedAdDialog(
        rewardTitle: rewardTitle,
        onRewardEarned: onRewardEarned,
      ),
    );
    return res ?? false;
  }

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  int _secondsLeft = 5;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          _completed = true;
          _timer?.cancel();
          UserStore.instance.recordRewardedAdWatched();
          widget.onRewardEarned();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _completed ? '✅ ÖDÜL KAZANILDI' : '🎬 SPONSORLU REKLAM ($_secondsLeft sn)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
                if (_completed)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4F46E5)),
              ),
              child: Column(
                children: [
                  Icon(
                    _completed ? Icons.verified_rounded : Icons.play_circle_fill_rounded,
                    size: 54,
                    color: _completed ? const Color(0xFF34D399) : const Color(0xFF818CF8),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CineLingo PRO ile Sınırları Kaldır!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reklamsız dizi/film sahneleri, sınırsız can ve tüm B2-C1 VIP replik analizlerine anında erişin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (5 - _secondsLeft) / 5,
                      minHeight: 7,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ödül: ${widget.rewardTitle}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _completed ? const Color(0xFF10B981) : const Color(0xFF374151),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _completed ? () => Navigator.of(context).pop(true) : null,
                child: Text(
                  _completed ? 'Ödülü Al ve Devam Et 🎉' : 'Lütfen Bekleyin ($_secondsLeft sn)...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. SAHNE SONU GEÇİŞ REKLAMI (Interstitial Ad - Ücretsiz kullanıcılara gösterilir)
class InterstitialAdDialog extends StatefulWidget {
  const InterstitialAdDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    if (UserStore.instance.isVip || UserStore.instance.isCheatUnlocked) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InterstitialAdDialog(),
    );
  }

  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  int _countdown = 4;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    UserStore.instance.recordInterstitialShown();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSkip = _countdown <= 0;
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📢 Reklam Molası',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
                ),
                TextButton(
                  onPressed: canSkip ? () => Navigator.of(context).pop() : null,
                  child: Text(
                    canSkip ? 'Reklamı Geç ⏭️' : '$_countdown sn sonra geç',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: canSkip ? const Color(0xFF38BDF8) : Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF311042), Color(0xFF4C1D95)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('👑', style: TextStyle(fontSize: 42)),
                  SizedBox(height: 8),
                  Text(
                    'Reklamlardan Sıkıldın mı?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'CineLingo PRO ile reklamları tamamen kaldır, sınırsız can kazan ve 25+ VIP film sahnesini hemen aç!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  CineLingoProSheet.show(context);
                },
                icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                label: const Text('REKLAMLARI KALDIR (PRO)', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4. VIP SAHNE KİLİT AÇMA EKRANI (Hem Reklamla Hem Elmasla Hem Abonelikle Gelir Modeli)
class VipClipUnlockSheet extends StatelessWidget {
  final ClipItem clip;
  final VoidCallback onUnlocked;

  const VipClipUnlockSheet({
    super.key,
    required this.clip,
    required this.onUnlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required ClipItem clip,
    required VoidCallback onUnlocked,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VipClipUnlockSheet(clip: clip, onUnlocked: onUnlocked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStore.instance;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: Color(0xFF374151), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            '👑 VIP Sahne: ${clip.series}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            clip.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 18),
          // Seçenek 1: Ödüllü Reklam İzle & Ücretsiz Aç
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final watched = await RewardedAdDialog.show(
                  context,
                  rewardTitle: '"${clip.series}" Sahnesi Kilidi Açıldı',
                  onRewardEarned: () {
                    store.unlockClipFromRewardedAd(clip.id);
                  },
                );
                if (watched) {
                  onUnlocked();
                }
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
              label: const Text(
                'Kısa Reklam İzle & Ücretsiz Aç 🎬',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Seçenek 2: Elmas ile Aç
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (store.unlockClipWithGems(clip)) {
                  Navigator.of(context).pop();
                  onUnlocked();
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yetersiz Elmas! Mağazadan elmas alabilir veya reklam izleyebilirsiniz.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  CineLingoProSheet.show(context);
                }
              },
              icon: const Text('💎', style: TextStyle(fontSize: 16)),
              label: Text(
                '${clip.gemCost} Elmas ile Kalıcı Aç (Mevcut: ${store.gems} 💎)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Seçenek 3: CineLingo PRO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                CineLingoProSheet.show(context);
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
              label: const Text(
                'CineLingo PRO ile Tüm Sahneleri Aç 👑',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. CİNELİNGO PRO ABONELİK & ELMAS MAĞAZASI (Ana Gelir / Monetization Ekranı)
class CineLingoProSheet extends StatefulWidget {
  const CineLingoProSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CineLingoProSheet(),
    );
  }

  @override
  State<CineLingoProSheet> createState() => _CineLingoProSheetState();
}

class _CineLingoProSheetState extends State<CineLingoProSheet> {
  int _selectedPlan = 1; // 0: Aylık, 1: Yıllık (%60 İndirim), 2: Ömür Boyu

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserStore.instance,
      builder: (context, _) {
        final store = UserStore.instance;
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.6,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0B0F19),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF374151), width: 1.5)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Üst Başlık
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('👑', style: TextStyle(fontSize: 26)),
                          SizedBox(width: 8),
                          Text(
                            'CineLingo PRO & Mağaza',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mevcut Bakiye Özeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Text('❤️ ', style: TextStyle(fontSize: 16)),
                            Text(
                              store.isVip ? 'Sınırsız Can' : '${store.hearts}/${UserStore.maxHearts} Can',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('💎 ', style: TextStyle(fontSize: 16)),
                            Text(
                              '${store.gems} Elmas',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: store.isVip ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            store.isVip ? '👑 PRO AKTİF' : 'ÜCRETSİZ PLAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: store.isVip ? Colors.amber : Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PRO Avantajları Kartı
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ CineLingo PRO Ayrıcalıkları',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow('🎬', '25+ Tüm VIP Film & Dizi Sahnelerine Sınırsız Erişim'),
                        _buildBenefitRow('♾️', 'Sınırsız Can (Hata Yapsan Bile Kesintisiz Öğren)'),
                        _buildBenefitRow('🚫', '%100 Reklamsız Deneyim (Geçiş Reklamlarını Kaldır)'),
                        _buildBenefitRow('📚', 'Tüm Kelime Kartları, Native Telaffuz & Çevrimdışı Mod'),
                        const SizedBox(height: 14),

                        // Abonelik Seçenekleri
                        _buildPlanOption(
                          index: 1,
                          title: 'Yıllık PRO Planı',
                          subtitle: 'Aylık sadece ₺33,33 • +500 💎 Hediye',
                          price: '₺399,99 / yıl',
                          badge: '%60 İNDİRİM • EN POPÜLER',
                        ),
                        const SizedBox(height: 8),
                        _buildPlanOption(
                          index: 0,
                          title: 'Aylık PRO Planı',
                          subtitle: 'İstediğin zaman iptal et • +150 💎 Hediye',
                          price: '₺79,99 / ay',
                        ),
                        const SizedBox(height: 8),
                        _buildPlanOption(
                          index: 2,
                          title: 'Ömür Boyu (Lifetime) VIP',
                          subtitle: 'Tek seferlik ödeme, sonsuza kadar PRO + 1.500 💎',
                          price: '₺699,99',
                          badge: 'TEK ÖDEME',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              final bonus = _selectedPlan == 2 ? 1500 : (_selectedPlan == 1 ? 500 : 150);
                              store.activateVipSubscription(bonusGems: bonus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 CineLingo PRO Aktif Edildi! +$bonus 💎 Elmas hesabınıza yüklendi.'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              store.isVip ? '👑 PRO ABONELİĞİNİZ AKTİF' : 'PRO ABONELİĞİ BAŞLAT 🚀',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ÜCRETSİZ ÖDÜLLÜ REKLAM & CAN DOLDURMA
                  const Text(
                    '🎁 Ücretsiz Ödüller & Hızlı İşlemler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStoreActionCard(
                          emoji: '🎬',
                          title: 'Reklam İzle',
                          subtitle: '+40 💎 Elmas & +1 ❤️',
                          buttonText: 'ÜCRETSİZ İZLE',
                          color: const Color(0xFF10B981),
                          onTap: () async {
                            await RewardedAdDialog.show(
                              context,
                              rewardTitle: '+40 💎 Elmas ve +1 ❤️ Can',
                              onRewardEarned: () {
                                store.addGems(40);
                                store.gainHearts(1);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStoreActionCard(
                          emoji: '❤️',
                          title: 'Canları Doldur',
                          subtitle: '5/5 Tam Can Paketi',
                          buttonText: '50 💎 HARCA',
                          color: const Color(0xFFEF4444),
                          onTap: () {
                            if (store.buyHeartRefillWithGems()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❤️ Canlarınız 5/5 olarak dolduruldu!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Yetersiz elmas! Reklam izleyerek veya paket alarak elmas kazanabilirsiniz.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ELMAS PAKETLERİ (In-App Purchase)
                  const Text(
                    '💎 Elmas Paketleri (Uygulama İçi Satın Alma)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildGemPackTile(
                    gems: 250,
                    title: 'Başlangıç Elmas Paketi (250 💎)',
                    subtitle: '6 VIP film sahnesini kalıcı olarak açar',
                    price: '₺29,99',
                    onBuy: () => _buyGems(context, 250, '₺29,99'),
                  ),
                  const SizedBox(height: 8),
                  _buildGemPackTile(
                    gems: 750,
                    title: 'Sinema Tutkunu Paketi (750 💎)',
                    subtitle: '+%25 Bonus Elmas • 18 VIP sahne açar',
                    price: '₺69,99',
                    isPopular: true,
                    onBuy: () => _buyGems(context, 750, '₺69,99'),
                  ),
                  const SizedBox(height: 8),
                  _buildGemPackTile(
                    gems: 2000,
                    title: 'Dev Stüdyo Paketi (2.000 💎)',
                    subtitle: 'En Avantajlı Paket • Tüm sahneler ve sınırsız can için ideal',
                    price: '₺149,99',
                    onBuy: () => _buyGems(context, 2000, '₺149,99'),
                  ),

                  const SizedBox(height: 20),

                  // Promosyon Kodu Butonu
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA5B4FC),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      CineLingoPromoDialog.show(context);
                    },
                    icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                    label: const Text('Promosyon veya İndirim Kodun Var mı?'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _buyGems(BuildContext context, int amount, String price) {
    UserStore.instance.addGems(amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💎 +$amount Elmas ($price) hesabınıza başarıyla eklendi!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required int index,
    required String title,
    required String subtitle,
    required String price,
    String? badge,
  }) {
    final isSelected = _selectedPlan == index;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4338CA).withValues(alpha: 0.45) : const Color(0xFF111827).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber : const Color(0xFF4F46E5).withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? Colors.amber : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onTap,
              child: Text(buttonText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemPackTile({
    required int gems,
    required String title,
    required String subtitle,
    required String price,
    required VoidCallback onBuy,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPopular ? const Color(0xFF38BDF8) : const Color(0xFF374151),
          width: isPopular ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onBuy,
            child: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// 6. CANLARIN BİTTİ DİYALOĞU (Out of Hearts)
class OutOfHeartsDialog extends StatelessWidget {
  const OutOfHeartsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const OutOfHeartsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStore.instance;
    return Dialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            const Text(
              'Canların Tükendi!',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Devam etmek için kısa bir ödüllü reklam izleyebilir, elmas kullanabilir veya PRO\'ya geçerek sınırsız can alabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await RewardedAdDialog.show(
                    context,
                    rewardTitle: '+2 ❤️ Can Eklendi',
                    onRewardEarned: () => store.gainHearts(2),
                  );
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Reklam İzle (+2 ❤️ Kazan)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (store.buyHeartRefillWithGems()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                    CineLingoProSheet.show(context);
                  }
                },
                icon: const Text('💎'),
                label: Text('50 Elmas ile Ful\'le (Mevcut: ${store.gems} 💎)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  CineLingoProSheet.show(context);
                },
                icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                label: const Text('Sınırsız Can İçin PRO\'ya Geç 👑', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
