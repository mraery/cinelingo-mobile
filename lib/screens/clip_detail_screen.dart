import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/clip_model.dart';

class ClipDetailScreen extends StatefulWidget {
  final ClipItem clip;
  final VoidCallback onClipCompleted;

  const ClipDetailScreen({
    super.key,
    required this.clip,
    required this.onClipCompleted,
  });

  @override
  State<ClipDetailScreen> createState() => _ClipDetailScreenState();
}

class _ClipDetailScreenState extends State<ClipDetailScreen> {
  late YoutubePlayerController _controller;
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  bool _showReview = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.clip.youtubeId,
      autoPlay: true,
      startSeconds: widget.clip.startSeconds.toDouble(),
      endSeconds: widget.clip.endSeconds > 0 ? widget.clip.endSeconds.toDouble() : null,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        showVideoAnnotations: false,
        origin: 'https://www.youtube.com',
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _onOptionSelected(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.clip.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _showReview = true;
      });
      widget.onClipCompleted();
    }
  }

  void _seekRelative(int seconds) async {
    final currentPos = await _controller.currentTime;
    final newPos = currentPos + seconds;
    _controller.seekTo(seconds: newPos < 0 ? 0.0 : newPos);
  }

  void _restartClip() {
    _controller.seekTo(seconds: widget.clip.startSeconds.toDouble());
    _controller.playVideo();
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller.setPlaybackRate(speed);
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.clip.questions;
    final currentQ = questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clip.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${widget.clip.series} • ${widget.clip.level} • ${widget.clip.accent}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // YouTube Player Widget (Official Cake Style Embed)
            Container(
              color: Colors.black,
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),

                // Cake-Style Smart Learning Bar
                Container(
                  color: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Replay 5 seconds (Repeat phrase)
                      IconButton(
                        icon: const Icon(Icons.replay_5, color: Colors.white70, size: 22),
                        tooltip: '5 saniye geri al (Cümleyi tekrar dinle)',
                        onPressed: () => _seekRelative(-5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_5, color: Colors.white70, size: 22),
                        tooltip: '5 saniye ileri',
                        onPressed: () => _seekRelative(5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay, color: Colors.white70, size: 20),
                        tooltip: 'Sahneyi baştan başlat',
                        onPressed: _restartClip,
                      ),
                      const Spacer(),
                      // Speed Controls (Slow listening mode for speech comprehension)
                      ...[0.75, 1.0, 1.25].map((s) {
                        final isSel = _playbackSpeed == s;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => _setSpeed(s),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${s}x',
                                style: TextStyle(
                                  fontSize: 11,
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

                const SizedBox(height: 12),

                // Content: Either Questions OR Transcript Review
                if (!_showReview) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress & Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Soru ${_currentQuestionIndex + 1} / ${questions.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                            ),
                            Text(
                              currentQ.type == 'comprehension'
                                  ? 'Diyalog Anlama'
                                  : currentQ.type == 'cloze'
                                      ? 'Boşluk Doldurma'
                                      : 'Dinleme & Telaffuz',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Question Prompt
                        Text(
                          currentQ.prompt,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Options List
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
                              bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
                              textColor = const Color(0xFF6EE7B7);
                            } else if (isSelected && !isCorrect) {
                              borderColor = const Color(0xFFEF4444);
                              bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
                              textColor = const Color(0xFFFCA5A5);
                            } else {
                              bgColor = const Color(0xFF111827);
                              textColor = Colors.white38;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _onOptionSelected(idx),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        letter,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (_isAnswered && isCorrect)
                                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                    if (_isAnswered && isSelected && !isCorrect)
                                      const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Explanation Box
                        if (_isAnswered) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Açıklama & Dinleme Notu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFBBF24),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentQ.explanation,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _nextQuestion,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              _currentQuestionIndex < questions.length - 1 ? 'Sonraki Soru' : 'Sonuçları & Transkripti Aç',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Completed Review Tab
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 36),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tebrikler! Sahne Tamamlandı',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    Text(
                                      '+50 XP kazandın! Artık sahnenin İngilizce ve Türkçe transkriptini inceleyebilirsin.',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Replik Replik Transkript:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),

                        ...widget.clip.transcript.map((line) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF374151)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${line.speaker}: ${line.text}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    line.trText,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            )),

                        const SizedBox(height: 16),

                        if (widget.clip.vocabulary.isNotEmpty) ...[
                          const Text(
                            'Öğrenilen Kelimeler & Deyimler:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ...widget.clip.vocabulary.map((vocab) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.circular(12),
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
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                                        ),
                                        Text(
                                          vocab.tr,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF34D399)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vocab.meaning,
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${vocab.example}"',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white38),
                                    ),
                                  ],
                                ),
                              )),
                        ],

                        const SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Diğer Sahnelere Dön', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
  }
}


