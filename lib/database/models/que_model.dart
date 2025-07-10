// database/models/que_model.dart
class Question {
  final String id;
  final String text;
  final List<String> options;
  final int answerIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'],
      text: json['question'],
      options: List<String>.from(json['options']),
      answerIndex: json['answer_index'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': text,
      'options': options,
      'answer_index': answerIndex,
    };
  }
}