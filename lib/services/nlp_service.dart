import 'package:intl/intl.dart';
import 'database.dart';
import '../models/note_status.dart';
import '../repositories/note_repository.dart';

// A simple class to hold structured NLP results, especially for lists.
class NlpResult {
  final String message;
  final List<Note> notes; // Relevant notes, if any

  NlpResult({required this.message, this.notes = const []});
}

class NlpService {
  // The main public method. It's now dependency-injected.
  Future<NlpResult> processQueryWithRepository(
    String query,
    NoteRepository repository,
  ) async {
    final lowerCaseQuery = query.toLowerCase().trim();

    if (lowerCaseQuery.isEmpty) {
      return NlpResult(message: "Please ask a question.");
    }

    try {
      // Intent: Counting items
      if (lowerCaseQuery.contains('how many')) {
        return await _handleCountQuery(lowerCaseQuery, repository);
      }

      // Intent: Listing items
      if (lowerCaseQuery.startsWith('show me') ||
          lowerCaseQuery.startsWith('list')) {
        return await _handleListQuery(lowerCaseQuery, repository);
      }

      // Intent: Creating a new note
      if ((lowerCaseQuery.startsWith('create') || lowerCaseQuery.startsWith('add')) &&
          lowerCaseQuery.contains('note')) {
        return await _handleCreateNoteQuery(lowerCaseQuery, repository);
      }

      return NlpResult(
          message:
              "Sorry, I don't understand that. Try 'how many unfinished tasks?', 'show me my notes from today', or 'create a new todo note titled \"My Task\"'.");
    } catch (e) {
      return NlpResult(message: "I encountered an error trying to understand that: $e");
    }
  }

  /// Filters a list of notes based on keywords in a query string.
  List<Note> _filterNotes(String query, List<Note> allNotes) {
    List<Note> filteredList = List.from(allNotes);

    // --- Filter by Status ---
    if (query.contains('unfinished') || query.contains(NoteStatus.todo)) {
      filteredList = filteredList
          .where((note) => note.status == NoteStatus.todo)
          .toList();
    } else if (query.contains(NoteStatus.inProgress.toLowerCase())) {
      filteredList = filteredList
          .where((note) => note.status == NoteStatus.inProgress)
          .toList();
    } else if (query.contains('finished') || query.contains(NoteStatus.done)) {
      filteredList = filteredList
          .where((note) => note.status == NoteStatus.done)
          .toList();
    }

    // --- Filter by Timeframe ---
    final now = DateTime.now();
    if (query.contains('today')) {
      filteredList = filteredList
          .where(
            (note) =>
                DateFormat('yyyy-MM-dd').format(note.createdAt) ==
                DateFormat('yyyy-MM-dd').format(now),
          )
          .toList();
    } else if (query.contains('last week')) {
      final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
      final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
      filteredList = filteredList.where((note) {
        return note.createdAt.isAfter(
              startOfLastWeek.subtract(const Duration(days: 1)),
            ) &&
            note.createdAt.isBefore(endOfLastWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (query.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      filteredList = filteredList
          .where(
            (note) =>
                DateFormat('yyyy-MM-dd').format(note.createdAt) ==
                DateFormat('yyyy-MM-dd').format(yesterday),
          )
          .toList();
    }

    return filteredList;
  }

  /// Handles "how many..." questions.
  Future<NlpResult> _handleCountQuery(
    String query,
    NoteRepository repository,
  ) async {
    // 1. Get all notes from the repository.
    final allNotes = await repository.getAllNotes();

    // 2. Filter the notes based on the query.
    final filteredNotes = _filterNotes(query, allNotes);
    final count = filteredNotes.length;

    // 3. Build a natural language response.
    String subject = "notes";
    if (query.contains('unfinished') || query.contains(NoteStatus.todo)) {
      subject = "unfinished tasks";
    } else if (query.contains(NoteStatus.inProgress.toLowerCase()))
      subject = "tasks in progress";
    else if (query.contains('finished') || query.contains(NoteStatus.done))
      subject = "finished tasks";

    String timeframe = "";
    if (query.contains('today')) {
      timeframe = " for today";
    } else if (query.contains('last week'))
      timeframe = " from last week";
    else if (query.contains('yesterday'))
      timeframe = " from yesterday";

    return NlpResult(message: "You have $count $subject$timeframe.");
  }

  /// Handles "show me..." or "list..." questions.
  Future<NlpResult> _handleListQuery(
    String query,
    NoteRepository repository,
  ) async {
    // 1. Get all notes.
    final allNotes = await repository.getAllNotes();

    // 2. Filter them.
    final filteredNotes = _filterNotes(query, allNotes);

    if (filteredNotes.isEmpty) {
      return NlpResult(message: "I couldn't find any notes that match your request.");
    }

    return NlpResult(
      message: "Found ${filteredNotes.length} note(s)", // Simplified message
      notes: filteredNotes, // Return the actual notes
    );
  }

  /// Handles "create..." or "add..." note questions.
  Future<NlpResult> _handleCreateNoteQuery(
    String query,
    NoteRepository repository,
  ) async {
    String title = "New Note"; // Default title
    String status = NoteStatus.todo; // Default status
    NoteType noteType = NoteType.text; // Default type
    String content = ""; // Default content for text notes

    // Try to extract title (e.g., "titled 'Buy groceries'")
    final titleRegex = RegExp(r"titled ['""]([^'""]*)['""]|called ['""]([^'""]*)['""]");
    final titleMatch = titleRegex.firstMatch(query);
    if (titleMatch != null) {
      title = titleMatch.group(1) ?? titleMatch.group(2) ?? title;
    } else {
      // Fallback: if no "titled" or "called", try to take text after "note "
      final noteKeywordIndex = query.indexOf("note ");
      if (noteKeywordIndex != -1) {
        final potentialTitle = query.substring(noteKeywordIndex + "note ".length).trim();
        if (potentialTitle.isNotEmpty) {
          // Remove status/type keywords if they are part of this fallback title
          title = potentialTitle.replaceAll(RegExp(r'\b(todo|in progress|done|list|text)\b', caseSensitive: false), '').trim();
          if (title.isEmpty) title = "New Note"; // Reset if stripping keywords left it empty
        }
      }
    }

    // Determine status
    if (query.contains(NoteStatus.inProgress.toLowerCase())) {
      status = NoteStatus.inProgress;
    } else if (query.contains(NoteStatus.done)) {
      status = NoteStatus.done;
    } else if (query.contains(NoteStatus.todo)) { // Explicit "todo" or default
      status = NoteStatus.todo;
    }

    // Determine note type
    if (query.contains("list note")) {
      noteType = NoteType.list;
      content = "[]"; // Empty JSON array for new list notes
    }

    await repository.addNote(
      title: title,
      content: content,
      status: status,
      noteType: noteType,
    );

    return NlpResult(message: "OK, I've created a ${noteType.name} note titled \"$title\" with status ${NoteStatus.displayText(status)}.");
  }
}
