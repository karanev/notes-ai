import '../database.dart'; // For Note type

// A simple class to hold structured NLP results, especially for lists.
class NlpResult {
  final String message;
  final List<Note> notes; // Relevant notes, if any

  NlpResult({required this.message, this.notes = const []});
}

// Enum to represent different NLP intents
enum NlpIntent {
  countTasks,
  listNotes,
  createNote,
  unknown,
}