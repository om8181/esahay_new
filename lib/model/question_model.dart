class Question {
  final String question;
  final String field; // key to store answer
  final List<String> options;

  Question({
    required this.question,
    required this.field,
    required this.options,
  });
}