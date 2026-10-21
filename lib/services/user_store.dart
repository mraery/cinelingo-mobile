import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/clip_model.dart';

class PromoResponse {
  final bool success;
  final bool isCheat;
  final String message;

  const PromoResponse({
    required this.success,
    required this.message,
    this.isCheat = false,
  });
}

class UserStore extends ChangeNotifier {
  static final UserStore instance = UserStore._internal();

  UserStore._internal() {
    _loadState();
  }

  static const int maxHearts = 5;

  int _hearts = 5;
  int _gems = 120;
  int _xp = 0;
  bool _isVip = false;
  bool _isCheatUnlocked = false;
  final Set<String> _unlockedClipIds = {};
  final Set<String> _completedClipIds = {};
  final Set<String> _usedPromoCodes = {};
  int _scenesWatchedSinceAd = 0;
  int _rewardedAdsWatched = 0;
  int _interstitialAdsShown = 0;

  // AdMob & Google Play Billing Yapılandırma Sabitleri (Canlıya alırken kendi ID'lerinizi yazabilirsiniz)
  static const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String admobBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String admobInterstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String admobRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  int get hearts => _hearts;
  int get gems => _gems;
  int get xp => _xp;
  bool get isVip => _isVip;
  bool get isCheatUnlocked => _isCheatUnlocked;
  Set<String> get unlockedClipIds => _unlockedClipIds;
  Set<String> get completedClipIds => _completedClipIds;
  int get rewardedAdsWatched => _rewardedAdsWatched;
  int get interstitialAdsShown => _interstitialAdsShown;

  bool isClipAccessible(ClipItem clip) {
    if (!clip.isVip) return true;
    if (_isVip || _isCheatUnlocked) return true;
    return _unlockedClipIds.contains(clip.id);
  }

  bool isClipCompleted(String clipId) => _completedClipIds.contains(clipId);

  File get _storageFile {
    return File('${Directory.systemTemp.path}/cinelingo_user_store_v2.json');
  }

  Future<void> _loadState() async {
    try {
      final file = _storageFile;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _hearts = (data['hearts'] as num?)?.toInt() ?? 5;
        _gems = (data['gems'] as num?)?.toInt() ?? 120;
        _xp = (data['xp'] as num?)?.toInt() ?? 0;
        _isVip = data['isVip'] as bool? ?? false;
        _isCheatUnlocked = data['isCheatUnlocked'] as bool? ?? false;
        _rewardedAdsWatched = (data['rewardedAdsWatched'] as num?)?.toInt() ?? 0;
        _interstitialAdsShown = (data['interstitialAdsShown'] as num?)?.toInt() ?? 0;

        final unlocked = (data['unlockedClipIds'] as List<dynamic>?)?.cast<String>() ?? [];
        _unlockedClipIds
          ..clear()
          ..addAll(unlocked);

        final completed = (data['completedClipIds'] as List<dynamic>?)?.cast<String>() ?? [];
        _completedClipIds
          ..clear()
          ..addAll(completed);

        final promos = (data['usedPromoCodes'] as List<dynamic>?)?.cast<String>() ?? [];
        _usedPromoCodes
          ..clear()
          ..addAll(promos);

        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final data = {
        'hearts': _hearts,
        'gems': _gems,
        'xp': _xp,
        'isVip': _isVip,
        'isCheatUnlocked': _isCheatUnlocked,
        'unlockedClipIds': _unlockedClipIds.toList(),
        'completedClipIds': _completedClipIds.toList(),
        'usedPromoCodes': _usedPromoCodes.toList(),
        'rewardedAdsWatched': _rewardedAdsWatched,
        'interstitialAdsShown': _interstitialAdsShown,
      };
      await _storageFile.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  void loseHeart() {
    if (_isVip || _isCheatUnlocked) return;
    if (_hearts > 0) {
      _hearts--;
      _saveState();
      notifyListeners();
    }
  }

  void gainHearts(int amount) {
    _hearts = (_hearts + amount).clamp(0, maxHearts);
    _saveState();
    notifyListeners();
  }

  void refillHearts() {
    _hearts = maxHearts;
    _saveState();
    notifyListeners();
  }

  bool buyHeartRefillWithGems() {
    if (_gems >= 50) {
      _gems -= 50;
      _hearts = maxHearts;
      _saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addGems(int amount) {
    _gems += amount;
    _saveState();
    notifyListeners();
  }

  bool unlockClipWithGems(ClipItem clip) {
    if (_gems >= clip.gemCost) {
      _gems -= clip.gemCost;
      _unlockedClipIds.add(clip.id);
      _saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  void unlockClipFromRewardedAd(String clipId) {
    _unlockedClipIds.add(clipId);
    _rewardedAdsWatched++;
    _saveState();
    notifyListeners();
  }

  void recordRewardedAdWatched() {
    _rewardedAdsWatched++;
    _saveState();
    notifyListeners();
  }

  void recordInterstitialShown() {
    _interstitialAdsShown++;
    _saveState();
    notifyListeners();
  }

  /// Sahne tamamlandığında çağrılır; ücretsiz kullanıcıda geçiş reklamı gösterilip gösterilmeyeceğini döner
  bool completeClipAndCheckInterstitial(String clipId, {int earnedXp = 50, int earnedGems = 15}) {
    if (!_completedClipIds.contains(clipId)) {
      _completedClipIds.add(clipId);
      _xp += earnedXp;
      _gems += earnedGems;
    } else {
      _xp += 15;
    }
    _scenesWatchedSinceAd++;
    _saveState();
    notifyListeners();

    if (_isVip || _isCheatUnlocked) return false;
    // Her sahne bitiminde (veya 2 sahnede bir) ücretsiz kullanıcıya geçiş reklamı göster
    if (_scenesWatchedSinceAd >= 1) {
      _scenesWatchedSinceAd = 0;
      return true;
    }
    return false;
  }

  void activateVipSubscription({int bonusGems = 300}) {
    _isVip = true;
    _hearts = maxHearts;
    _gems += bonusGems;
    _saveState();
    notifyListeners();
  }

  PromoResponse applyPromoCode(String rawCode) {
    final code = rawCode.trim().toLowerCase();
    if (code.isEmpty) {
      return const PromoResponse(
        success: false,
        message: 'Lütfen geçerli bir promosyon kodu girin.',
      );
    }

    // SADECE "kagan" YAZILINCA HİLELER AKTİF OLUR (veya tekrar yazılınca kapanır)
    if (code == 'kagan' || code == 'kagan123') {
      if (_isCheatUnlocked) {
        _isCheatUnlocked = false;
        _isVip = false;
        _hearts = maxHearts;
        _saveState();
        notifyListeners();
        return const PromoResponse(
          success: true,
          isCheat: false,
          message: '🔒 Kagan Hile Modu Kapatıldı!\n'
              '• OTO-ÇÖZ butonu gizlendi.\n'
              '• Normal 5 can ve reklamlı kullanıcı moduna dönüldü.',
        );
      } else {
        _isCheatUnlocked = true;
        _isVip = true;
        _hearts = maxHearts;
        if (_gems < 5000) _gems = 9999;
        _saveState();
        notifyListeners();
        return const PromoResponse(
          success: true,
          isCheat: true,
          message: '⚡ KAGAN ÖZEL HİLE MODU AKTİF EDİLDİ!\n'
              '• Sorularda "OTO-ÇÖZ ⚡" hile butonu açıldı!\n'
              '• Tüm VIP dizi & film sahnelerinin kilidi açıldı!\n'
              '• Sınırsız Can (∞) ve 9.999 💎 Elmas tanımlandı!\n'
              '(Kapatmak için tekrar kagan veya kapat yazabilirsin)',
        );
      }
    }

    if (code == 'kapat' || code == 'hilekapat') {
      _isCheatUnlocked = false;
      _isVip = false;
      _hearts = maxHearts;
      _saveState();
      notifyListeners();
      return const PromoResponse(
        success: true,
        isCheat: false,
        message: '🔒 Hile ve VIP Modu Kapatıldı. Normal kullanıcı moduna dönüldü.',
      );
    }

    if (code == 'sinema2026' || code == 'hosgeldin' || code == 'cinelingo50') {
      if (_usedPromoCodes.contains(code)) {
        return const PromoResponse(
          success: false,
          message: 'Bu hediye kodunu daha önce kullandınız.',
        );
      }
      _usedPromoCodes.add(code);
      _gems += 75;
      _hearts = maxHearts;
      _saveState();
      notifyListeners();
      return const PromoResponse(
        success: true,
        isCheat: false,
        message: '🎁 Kampanya Kodu Uygulandı!\n'
            '• Hesabınıza +75 💎 Elmas eklendi.\n'
            '• Canlarınız 5/5 olarak dolduruldu!',
      );
    }

    return const PromoResponse(
      success: false,
      message: 'Geçersiz veya süresi dolmuş promosyon kodu.',
    );
  }
}
