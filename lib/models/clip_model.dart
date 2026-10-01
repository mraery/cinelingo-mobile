class Question {
  final String id;
  final String type; // 'comprehension', 'listening', 'cloze', 'vocabulary'
  final String prompt;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

class TranscriptLine {
  final String speaker;
  final String text;
  final String trText;

  const TranscriptLine({
    required this.speaker,
    required this.text,
    required this.trText,
  });
}

class VocabItem {
  final String word;
  final String tr;
  final String meaning;
  final String example;

  const VocabItem({
    required this.word,
    required this.tr,
    required this.meaning,
    required this.example,
  });
}

class ClipItem {
  final String id;
  final String title;
  final String series;
  final String level; // A2, B1, B2, C1
  final String accent; // Amerikan, İngiliz
  final String genre;
  final String youtubeId;
  final int startSeconds;
  final int endSeconds;
  final String description;
  final List<Question> questions;
  final List<TranscriptLine> transcript;
  final List<VocabItem> vocabulary;

  const ClipItem({
    required this.id,
    required this.title,
    required this.series,
    required this.level,
    required this.accent,
    required this.genre,
    required this.youtubeId,
    required this.startSeconds,
    required this.endSeconds,
    required this.description,
    required this.questions,
    required this.transcript,
    required this.vocabulary,
  });
}
