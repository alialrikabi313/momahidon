// يمكنك نقل هذا الملف إلى مكان اسمه models أو data_models
class Question {
  final String questionText;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctIndex,
  });

  // دالة لتحويل Map من Firestore إلى كائن Question
  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
    );
  }
}

class Competition {
  final String title;
  final List<Question> questions;

  Competition({
    required this.title,
    required this.questions,
  });

  // دالة لتحويل Map من Firestore إلى كائن Competition
  factory Competition.fromMap(Map<String, dynamic> data) {
    return Competition(
      title: data['title'] ?? '',
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
