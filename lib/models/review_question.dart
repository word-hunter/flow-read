class ReviewQuestion {
  final String id;
  final String question;
  final String hint;
  final bool isCompleted;

  const ReviewQuestion({
    required this.id,
    required this.question,
    required this.hint,
    this.isCompleted = false,
  });

  ReviewQuestion copyWith({
    bool? isCompleted,
  }) {
    return ReviewQuestion(
      id: id,
      question: question,
      hint: hint,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
