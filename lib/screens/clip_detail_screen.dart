import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/clip_model.dart';
import '../services/user_store.dart';
import '../widgets/monetization_dialogs.dart';

class ClipDetailScreen extends StatefulWidget {
  final ClipItem clip;
  final VoidCallback? onClipCompleted;

  const ClipDetailScreen({
    super.key,
    required this.clip,
    this.onClipCompleted,
  });

  @override
  State<ClipDetailScreen> createState() => _ClipDetailScreenState();
}

class _ClipDetailScreenState extends State<ClipDetailScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  StreamSubscription<YoutubeVideoState>? _youtubeStateSub;
  StreamSubscription<YoutubePlayerValue>? _youtubePlayerStateSub;
  Duration _youtubePos = Duration.zero;
  late TabController _tabController;

  bool get _isYoutube => widget.clip.videoAsset == null;

  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  bool _clipFinished = false;
  bool _isVideoCollapsed = false; // Videoyu küçültüp sorulara tam ekran sağlama

  int _currentQuestionIndex = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _showReview = false;
  int _correctAnswerCount = 0;
  int? _highlightedLineIndex;
  final ScrollController _questionScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final assetPath = widget.clip.videoAsset;
    if (assetPath != null) {
      // 1. Çevrimdışı Gömülü Video (Offline MP4)
      _videoController = VideoPlayerController.asset(assetPath);
      try {
        await _videoController!.initialize();
        _videoController!.addListener(_videoListener);

        if (widget.clip.startSeconds > 0) {
          await _videoController!.seekTo(Duration(seconds: widget.clip.startSeconds));
        }

        await _videoController!.play();
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
            _isPlaying = true;
          });
        }
      } catch (e) {
        debugPrint('Video error: $e');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      }
    } else {
      // 2. Çevrimiçi YouTube Akışı (Hafif Paket Boyutu - v10.0.1)
      try {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: widget.clip.youtubeId,
          autoPlay: true,
          startSeconds: widget.clip.startSeconds.toDouble(),
          params: const YoutubePlayerParams(
            showControls: false,
            showFullscreenButton: false,
            mute: false,
            enableCaption: false,
            strictRelatedVideos: true,
          ),
        );

        _youtubeStateSub = _youtubeController!.videoStateStream.listen((state) {
          if (!mounted) return;
          _youtubePos = state.position;
          final posSec = state.position.inSeconds;
          final endLimit = widget.clip.endSeconds > 0
              ? widget.clip.endSeconds
              : _youtubeController!.metadata.duration.inSeconds;

          if (posSec >= endLimit && !_clipFinished && endLimit > 0) {
            _onClipEnded();
          }
        });

        _youtubePlayerStateSub = _youtubeController!.listen((value) {
          if (!mounted) return;
          final isPlayingNow = value.playerState == PlayerState.playing;
          if (isPlayingNow != _isPlaying) {
            setState(() {
              _isPlaying = isPlayingNow;
            });
          }
          if (value.playerState == PlayerState.ended) {
            _onClipEnded();
          }
        });

        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
            _isPlaying = true;
          });
        }
      } catch (e) {
        debugPrint('YouTube player error: $e');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;

    final isPlayingNow = _videoController!.value.isPlaying;
    if (isPlayingNow != _isPlaying) {
      setState(() {
        _isPlaying = isPlayingNow;
      });
    }

    final posSec = _videoController!.value.position.inSeconds;
    final endLimit = widget.clip.endSeconds > 0
        ? widget.clip.endSeconds
        : _videoController!.value.duration.inSeconds;

    // Sahne bittiğinde
    if (posSec >= endLimit && !_clipFinished && endLimit > 0) {
      _onClipEnded();
    }
  }

  void _onClipEnded() {
    if (_clipFinished) return;
    try {
      if (_isYoutube) {
        _youtubeController?.pauseVideo();
      } else {
        _videoController?.pause();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _clipFinished = true;
        _isPlaying = false;
        _showControls = true;
        _isVideoCollapsed = true; // Soru alanını ferahlatmak için videoyu otomatik küçült
      });
      _tabController.animateTo(0);
    }
  }

  void _togglePlayPause() {
    if (_isYoutube) {
      if (_youtubeController == null) return;
      if (_isPlaying) {
        _youtubeController!.pauseVideo();
      } else {
        if (_clipFinished) {
          _restartClip();
        } else {
          _youtubeController!.playVideo();
        }
      }
    } else {
      if (_videoController == null || !_isVideoInitialized) return;
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        if (_clipFinished) {
          _restartClip();
        } else {
          _videoController!.play();
        }
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _restartClip() {
    setState(() {
      _clipFinished = false;
      _isPlaying = true;
    });
    if (_isYoutube) {
      _youtubeController?.seekTo(seconds: widget.clip.startSeconds.toDouble(), allowSeekAhead: true);
      _youtubeController?.playVideo();
    } else {
      if (_videoController == null) return;
      _videoController!.seekTo(Duration(seconds: widget.clip.startSeconds));
      _videoController!.play();
    }
  }

  void _seekRelative(int seconds) {
    if (_isYoutube) {
      if (_youtubeController == null) return;
      final current = _youtubePos;
      final target = current + Duration(seconds: seconds);
      final clamped = target < Duration.zero ? Duration.zero : target;
      _youtubePos = clamped;
      _youtubeController!.seekTo(seconds: clamped.inSeconds.toDouble(), allowSeekAhead: true);
    } else {
      if (_videoController == null) return;
      final current = _videoController!.value.position;
      final target = current + Duration(seconds: seconds);
      final clamped = target < Duration.zero ? Duration.zero : target;
      _videoController!.seekTo(clamped);
    }
  }

  void _seekToSecond(int second, int lineIndex) {
    setState(() {
      _highlightedLineIndex = lineIndex;
      _clipFinished = false;
    });
    if (_isYoutube) {
      if (_youtubeController == null) return;
      _youtubePos = Duration(seconds: second);
      _youtubeController!.seekTo(seconds: second.toDouble(), allowSeekAhead: true);
      _youtubeController!.playVideo();
    } else {
      if (_videoController == null) return;
      _videoController!.seekTo(Duration(seconds: second));
      _videoController!.play();
    }
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_isYoutube) {
      _youtubeController?.setPlaybackRate(speed);
    } else {
      _videoController?.setPlaybackSpeed(speed);
    }
  }

  void _onOptionSelected(int index) {
    if (_isAnswered) return;
    final store = UserStore.instance;
    if (!store.isVip && !store.isCheatUnlocked && store.hearts <= 0) {
      OutOfHeartsDialog.show(context);
      return;
    }

    final questions = widget.clip.questions;
    if (questions.isEmpty) return;

    final currentQ = questions[_currentQuestionIndex];
    final isCorrect = index == currentQ.correctAnswerIndex;

    if (!isCorrect) {
      store.loseHeart();
      if (!store.isVip && !store.isCheatUnlocked && store.hearts <= 0) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) OutOfHeartsDialog.show(context);
        });
      }
    }

    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      if (isCorrect) {
        _correctAnswerCount++;
      }
    });

    if (_questionScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_questionScrollController.hasClients) {
          _questionScrollController.animateTo(
            _questionScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _nextQuestion() {
    final questions = widget.clip.questions;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
      if (_questionScrollController.hasClients) {
        _questionScrollController.jumpTo(0.0);
      }
    } else {
      setState(() {
        _showReview = true;
      });
      final shouldShowInterstitial =
          UserStore.instance.completeClipAndCheckInterstitial(widget.clip.id);
      widget.onClipCompleted?.call();
      if (shouldShowInterstitial) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) InterstitialAdDialog.showIfNeeded(context);
        });
      }
    }
  }

  void _safeExit() {
    try {
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    try {
      _youtubeController?.pauseVideo();
      _youtubeController?.close();
    } catch (_) {}
    Navigator.of(context).pop();
  }

  Future<void> _openInYouTubeApp() async {
    final startSec = widget.clip.startSeconds;
    final url = Uri.parse(
        'https://www.youtube.com/watch?v=${widget.clip.youtubeId}&t=${startSec}s');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _youtubeStateSub?.cancel();
    _youtubePlayerStateSub?.cancel();
    _youtubeController?.close();
    _tabController.dispose();
    _questionScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.clip.questions;
    final currentQ = questions.isNotEmpty && _currentQuestionIndex < questions.length
        ? questions[_currentQuestionIndex]
        : null;

    return ListenableBuilder(
      listenable: UserStore.instance,
      builder: (context, _) {
        final store = UserStore.instance;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            try {
              _videoController?.pause();
              _videoController?.dispose();
            } catch (_) {}
            try {
              _youtubeController?.pauseVideo();
              _youtubeController?.close();
            } catch (_) {}
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0B0F19),
            appBar: AppBar(
              backgroundColor: const Color(0xFF111827),
              elevation: 2,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                tooltip: 'Geri Dön',
                onPressed: _safeExit,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.clip.series} • ${widget.clip.level} • ${widget.clip.accent}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              actions: [
                // Can Göstergesi
                InkWell(
                  onTap: () => CineLingoProSheet.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          (store.isVip || store.isCheatUnlocked) ? '∞' : '${store.hearts}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // Promosyon Kodu Butonu (kagan yazılınca hile açılır)
                IconButton(
                  icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFA5B4FC), size: 20),
                  tooltip: 'Promosyon Kodu',
                  onPressed: () => CineLingoPromoDialog.show(context),
                ),
                // Video Boyutunu Değiştir Butonu
                IconButton(
                  icon: Icon(
                    _isVideoCollapsed ? Icons.fit_screen_rounded : Icons.vertical_align_bottom_rounded,
                    color: const Color(0xFFA5B4FC),
                    size: 22,
                  ),
                  tooltip: _isVideoCollapsed ? 'Videoyu Göster' : 'Soruları Büyüt / Videoyu Gizle',
                  onPressed: () {
                    setState(() {
                      _isVideoCollapsed = !_isVideoCollapsed;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'YouTube\'da Aç',
                  onPressed: _openInYouTubeApp,
                ),
              ],
            ),
            body: Column(
          children: [
            // 1. VİDEO BÖLÜMÜ (Açıkken 190px kompakt, kapalıyken 46px akıllı mini-bar)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isVideoCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildExpandedVideoArea(),
              secondChild: _buildCollapsedMiniBar(),
            ),

            // 2. SEKMELER (SORULAR | DİYALOG | KELİMELER)
            Container(
              color: const Color(0xFF161F30),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6366F1),
                indicatorWeight: 3,
                labelColor: const Color(0xFFA5B4FC),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.quiz_rounded, size: 17),
                    text: 'Sorular (${questions.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.subtitles_rounded, size: 17),
                    text: 'Diyalog (${widget.clip.transcript.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.auto_stories_rounded, size: 17),
                    text: 'Kelimeler (${widget.clip.vocabulary.length})',
                  ),
                ],
              ),
            ),

            // 3. TAM EKRAN FERAH İÇERİK ALANI
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(), // Yatay takılmayı önler
                children: [
                  _buildQuestionsTab(context, questions, currentQ),
                  _buildTranscriptTab(),
                  _buildVocabularyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  /// 1-A. AÇIK VİDEO ALANI (Entegre Dokunmatik Kontroller)
  Widget _buildExpandedVideoArea() {
    // 1. Çevrimiçi YouTube Oynatıcı
    if (_isYoutube && _youtubeController != null) {
      return Container(
        height: 160,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: YoutubePlayer(
                controller: _youtubeController!,
                aspectRatio: 16 / 9,
              ),
            ),

            // Üst Sağ: "Soruları Büyüt" Butonu
            Positioned(
              top: 6,
              right: 8,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isVideoCollapsed = true;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.expand_more_rounded, color: Color(0xFFA5B4FC), size: 16),
                      SizedBox(width: 3),
                      Text(
                        'Soruları Büyüt',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Üst Sol: Hızlı Çıkış Butonu
            Positioned(
              top: 6,
              left: 8,
              child: InkWell(
                onTap: _safeExit,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 3),
                      Text('Çıkış', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // Sahne Bittiğinde Görünen Tebrik Katmanı
            if (_clipFinished)
              _buildClipFinishedOverlay(),
          ],
        ),
      );
    }

    // 2. Çevrimdışı Gömülü Video Oynatıcı (Offline MP4)
    final currentPos = _videoController?.value.position ?? Duration.zero;
    final totalDur = _videoController?.value.duration ?? Duration.zero;

    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_videoController != null && _isVideoInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio > 0
                      ? _videoController!.value.aspectRatio
                      : (16 / 9),
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 10),
                    Text(
                      'Sahne Yükleniyor...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Ortadaki Büyük Oynat / Durdur Butonu
            if (_showControls && _isVideoInitialized && !_clipFinished)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.replay_5_rounded, color: Colors.white70),
                      onPressed: () => _seekRelative(-5),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.forward_5_rounded, color: Colors.white70),
                      onPressed: () => _seekRelative(5),
                    ),
                  ],
                ),
              ),

            // Üst Sağ: "Soruları Genişlet" Butonu
            Positioned(
              top: 6,
              right: 8,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isVideoCollapsed = true;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.expand_more_rounded, color: Color(0xFFA5B4FC), size: 16),
                      SizedBox(width: 3),
                      Text(
                        'Soruları Büyüt',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Üst Sol: Hızlı Çıkış Butonu
            Positioned(
              top: 6,
              left: 8,
              child: InkWell(
                onTap: _safeExit,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 11),
                      SizedBox(width: 3),
                      Text('Çıkış', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // Alt Entegre Zaman Çizgisi ve Hızlar
            if (_showControls && _isVideoInitialized && !_clipFinished)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(currentPos),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            activeTrackColor: const Color(0xFF6366F1),
                            inactiveTrackColor: Colors.white30,
                            thumbColor: const Color(0xFFA5B4FC),
                          ),
                          child: Slider(
                            value: currentPos.inMilliseconds.clamp(0, totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds : 1).toDouble(),
                            min: 0.0,
                            max: (totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds : 1).toDouble(),
                            onChanged: (val) {
                              _videoController?.seekTo(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(totalDur),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // Hız Butonları (Mini Chips)
                      ...[0.75, 1.0, 1.25].map((s) {
                        final isSel = _playbackSpeed == s;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => _setSpeed(s),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF6366F1) : Colors.black45,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${s}x',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Sahne Bittiğinde Görünen Tebrik Katmanı
            if (_clipFinished)
              _buildClipFinishedOverlay(),
          ],
        ),
      ),
    );
  }

  /// Sahne Tamamlandı Tebrik ve Tekrar Oynatma Katmanı
  Widget _buildClipFinishedOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 34),
            const SizedBox(height: 6),
            const Text(
              '🎬 Sahne Tamamlandı!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aşağıdaki soruyu çöz veya tekrar dinle.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _restartClip,
                  icon: const Icon(Icons.replay_rounded, size: 15),
                  label: const Text('Tekrar İzle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _clipFinished = false;
                      _isVideoCollapsed = true;
                    });
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.quiz_rounded, size: 15),
                  label: const Text('Soruyu Çöz 👇'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 1-B. AKILLI MİNİ-BAR (Sorulara ve Diyaloglara %100 Ferah Alan Bırakır)
  Widget _buildCollapsedMiniBar() {
    final currentPos = _isYoutube
        ? _youtubePos
        : (_videoController?.value.position ?? Duration.zero);

    return Container(
      color: const Color(0xFF1E1B4B),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Oynat / Durdur
          InkWell(
            onTap: _togglePlayPause,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.clip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatDuration(currentPos)} • ${_isYoutube ? "Çevrimiçi Yayın" : "Çevrimdışı Video"}',
                  style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 10.5),
                ),
              ],
            ),
          ),
          // Yeniden Dinle Butonu
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF312E81),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.replay_rounded, size: 14, color: Colors.amber),
            label: const Text('Tekrar Dinle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _restartClip,
          ),
          const SizedBox(width: 8),
          // Videoyu Genişlet Butonu
          InkWell(
            onTap: () {
              setState(() {
                _isVideoCollapsed = false;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Videoyu Aç', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SEKME 1: KAVRAMA SORULARI (Geniş, Ferah, Asla Takılmayan Alan)
  Widget _buildQuestionsTab(BuildContext context, List<Question> questions, Question? currentQ) {
    if (questions.isEmpty) {
      return const Center(
        child: Text('Bu sahne için soru bulunamadı.', style: TextStyle(color: Colors.white70)),
      );
    }

    if (_showReview) {
      return _buildResultCard(questions.length);
    }

    if (currentQ == null) return const SizedBox();

    return SingleChildScrollView(
      controller: _questionScrollController,
      physics: const AlwaysScrollableScrollPhysics(), // Her koşulda kusursuz dikey kaydırma
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Üst Kompakt Kontrol & Bilgi Satırı (Ferahlık için tek satır)
          Row(
            children: [
              // Soru Numarası
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Soru ${_currentQuestionIndex + 1} / ${questions.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA5B4FC),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Soru Türü
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: currentQ.type == 'grammar'
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : currentQ.type == 'idiom'
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                          : currentQ.type == 'vocabulary'
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : currentQ.type == 'cloze'
                                  ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                                  : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentQ.type == 'grammar'
                      ? '📘 Dil Bilgisi'
                      : currentQ.type == 'idiom'
                          ? '💡 Deyim'
                          : currentQ.type == 'vocabulary'
                              ? '🔤 Kelime'
                              : currentQ.type == 'cloze'
                                  ? '✍️ Boşluk'
                                  : currentQ.type == 'listening'
                                      ? '🎧 Dinleme'
                                      : '🎯 Anlama',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentQ.type == 'grammar'
                        ? const Color(0xFF93C5FD)
                        : currentQ.type == 'idiom'
                            ? const Color(0xFFFCD34D)
                            : currentQ.type == 'vocabulary'
                                ? const Color(0xFF6EE7B7)
                                : currentQ.type == 'cloze'
                                    ? const Color(0xFFF9A8D4)
                                    : const Color(0xFFC4B5FD),
                  ),
                ),
              ),
              const Spacer(),
              // Hızlı Yeniden Dinle
              InkWell(
                onTap: _restartClip,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 12, color: Colors.amber),
                      SizedBox(width: 3),
                      Text('Dinle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Videoyu Küçült / Büyüt (Soruları tek tıkla tam ekran yap)
              InkWell(
                onTap: () {
                  setState(() {
                    _isVideoCollapsed = !_isVideoCollapsed;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isVideoCollapsed ? const Color(0xFF4F46E5) : const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isVideoCollapsed ? const Color(0xFF818CF8) : const Color(0xFF4B5563)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isVideoCollapsed ? Icons.videocam_rounded : Icons.fullscreen_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _isVideoCollapsed ? 'Video Aç' : 'Büyüt ↕',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Soru Metni (Göz Yormayan, Kompakt & Okunaklı)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              currentQ.prompt,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 9),

          // 3. Şıklar (A, B, C, D - Ekranın Üst Kısmına Yanaşık, Seçmesi Kolay)
          ...currentQ.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final optionText = entry.value;
            final letter = String.fromCharCode(65 + idx);

            final isSelected = _selectedOption == idx;
            final isCorrect = idx == currentQ.correctAnswerIndex;

            Color borderColor = const Color(0xFF374151);
            Color bgColor = const Color(0xFF1F2937);
            Color textColor = Colors.white;

            if (_isAnswered) {
              if (isCorrect) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFF10B981).withValues(alpha: 0.2);
                textColor = const Color(0xFF6EE7B7);
              } else if (isSelected && !isCorrect) {
                borderColor = const Color(0xFFEF4444);
                bgColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
                textColor = const Color(0xFFFCA5A5);
              } else {
                bgColor = const Color(0xFF111827);
                textColor = Colors.white38;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                onTap: () => _onOptionSelected(idx),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (_isAnswered && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                      if (_isAnswered && isSelected && !isCorrect)
                        const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Henüz cevap verilmediğinde: GEÇ (ve sadece 'kagan' hilesi aktifse OTO-ÇÖZ)
          if (!_isAnswered) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _nextQuestion,
                    child: const Text('SORUYU GEÇ ⏭️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                if (UserStore.instance.isCheatUnlocked) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        _onOptionSelected(currentQ.correctAnswerIndex);
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                      label: const Text('OTO-ÇÖZ (HİLE) ⚡', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Cevap verildikten sonra: Açıklama ve Sonraki Soru
          if (_isAnswered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Açıklama & Dinleme Notu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentQ.explanation,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFFE2E8F0), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _nextQuestion,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _currentQuestionIndex < questions.length - 1 ? 'Sonraki Soru' : 'Sonuçları & Sahneyi Tamamla 🏆',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// TEBRİKLER & SKOR KARTI
  Widget _buildResultCard(int totalQ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 10),
                const Text(
                  'Sahne Başarıyla Tamamlandı!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Doğru Sayısı: $_correctAnswerCount / $totalQ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7)),
                ),
                const SizedBox(height: 12),
                const Text(
                  '+50 XP Kazandın! Sahnenin "Diyalog" sekmesinden replikleri tek tek dinleyebilir veya "Kelimeler" sekmesinden tekrar edebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                setState(() {
                  _currentQuestionIndex = 0;
                  _selectedOption = null;
                  _isAnswered = false;
                  _showReview = false;
                  _correctAnswerCount = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Soruları Tekrar Çöz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF374151), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _safeExit,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Diğer Sahnelere Dön', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  /// SEKME 2: DİYALOG (REPLİKLER - FERAH KAYDIRMA ALANI)
  Widget _buildTranscriptTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'İpucu: Herhangi bir repliğe dokunarak videoyu o saniyeden dinleyebilirsin.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          ...widget.clip.transcript.asMap().entries.map((entry) {
            final idx = entry.key;
            final line = entry.value;
            final isHighlighted = _highlightedLineIndex == idx;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color(0xFF312E81).withValues(alpha: 0.5)
                    : const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHighlighted ? const Color(0xFF818CF8) : const Color(0xFF374151),
                  width: isHighlighted ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    final sec = line.atSecond ?? widget.clip.startSeconds;
                    _seekToSecond(sec, idx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Oynat Butonu
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 2, right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFA5B4FC), size: 18),
                        ),
                        // Diyalog Metinleri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF374151),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      line.speaker,
                                      style: const TextStyle(
                                        color: Color(0xFFA5B4FC),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (line.atSecond != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${line.atSecond}s',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                line.text,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                line.trText,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF9CA3AF),
                                  height: 1.3,
                                ),
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
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// SEKME 3: KELİMELER
  Widget _buildVocabularyTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sahneden Öğrenilecek Kelimeler & Deyimler:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...widget.clip.vocabulary.map((vocab) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF374151)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vocab.word,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vocab.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vocab.meaning,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${vocab.example}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
