class Question {
  final String id;
  final String text;
  final String? image;
  final List<String> options;
  final int correctIndex;
  final String hint;
  final String topic;
  final int ticket;

  Question({
    required this.id,
    required this.text,
    this.image,
    required this.options,
    required this.correctIndex,
    required this.hint,
    required this.topic,
    required this.ticket,
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    final t = j['ticket'] ?? 1;
    return Question(
      id: j['id'].toString(),
      text: j['question'] ?? j['text'] ?? '',
      image: j['image_local'] ?? j['image'],
      options: List<String>.from(j['options'] ?? j['answers'] ?? []),
      correctIndex: j['correct_index'] ?? j['correct'] ?? j['correctIndex'] ?? 0,
      hint: j['hint'] ?? j['explanation'] ?? '',
      topic: j['topic'] ?? j['theme'] ?? 'Билет $t',
      ticket: t,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'question': text,
        'image_local': image,
        'options': options,
        'correct_index': correctIndex,
        'hint': hint,
        'topic': topic,
        'ticket': ticket,
      };
}
