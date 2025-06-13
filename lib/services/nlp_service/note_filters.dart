import 'package:intl/intl.dart';
import '../database.dart'; // For Note type
import '../../models/note_status.dart';

/// Abstract class for defining a note filter.
abstract class NoteFilter {
  /// Checks if this filter is relevant to the given query.
  bool isApplicable(String query);

  /// Checks if the given note matches the filter's criteria based on the query.
  /// This should only be called if `isApplicable` returned true for the same query.
  bool matches(Note note, String query);
}

/// Filters notes based on their status.
class StatusNoteFilter extends NoteFilter {
  @override
  bool isApplicable(String query) {
    return query.contains('unfinished') ||
        query.contains(NoteStatus.todo) ||
        query.contains(NoteStatus.inProgress.toLowerCase()) ||
        query.contains('finished') ||
        query.contains(NoteStatus.done);
  }

  @override
  bool matches(Note note, String query) {
    if (query.contains('unfinished') || query.contains(NoteStatus.todo)) {
      return note.status == NoteStatus.todo;
    }
    if (query.contains(NoteStatus.inProgress.toLowerCase())) {
      return note.status == NoteStatus.inProgress;
    }
    if (query.contains('finished') || query.contains(NoteStatus.done)) {
      return note.status == NoteStatus.done;
    }
    return true; // Fallback
  }
}

/// Filters notes based on their creation timeframe.
class TimeframeNoteFilter extends NoteFilter {
  @override
  bool isApplicable(String query) {
    return query.contains('today') ||
        query.contains('last week') ||
        query.contains('yesterday');
  }

  @override
  bool matches(Note note, String query) {
    final now = DateTime.now();
    if (query.contains('today')) {
      return DateFormat('yyyy-MM-dd').format(note.createdAt) ==
          DateFormat('yyyy-MM-dd').format(now);
    }
    if (query.contains('last week')) {
      final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
      final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
      return note.createdAt.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
             note.createdAt.isBefore(endOfLastWeek.add(const Duration(days: 1)));
    }
    if (query.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateFormat('yyyy-MM-dd').format(note.createdAt) ==
          DateFormat('yyyy-MM-dd').format(yesterday);
    }
    return true; // Fallback
  }
}