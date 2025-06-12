// lib/repositories/note_repository.dart

import '../services/database.dart'; // We need AppDatabase and the generated Note class
import 'package:drift/drift.dart'
    as drift; // Use a prefix to avoid name clashes

class NoteRepository {
  // The repository has a dependency on the database
  final AppDatabase _database;

  NoteRepository(this._database);

  // --- PUBLIC API FOR THE REST OF THE APP ---

  // Fetches all notes. The UI will use this.
  Stream<List<Note>> watchAllNotes() {
    return _database
        .watchAllNotes(); // For now, just pass through to the database
  }

  Future<List<Note>> getAllNotes() {
    return _database.getAllNotes();
  }

  // Adds a new note.
  Future<void> addNote({
    required String title,
    required String content,
    required String status,
  }) async {
    final newNote = NotesCompanion(
      title: drift.Value(title),
      content: drift.Value(content),
      status: drift.Value(status),
      createdAt: drift.Value(DateTime.now()),
    );
    await _database.insertNote(newNote);
  }

  // Updates an existing note.
  Future<void> updateNote(Note note) async {
    // The 'note' object from the UI is a drift 'Note' data class.
    // We convert it to a 'NotesCompanion' for the update operation.
    final companion = note.toCompanion(true);
    await _database.updateNote(companion);
  }

  // Deletes a note.
  Future<void> deleteNote(int id) async {
    await _database.deleteNote(id);
  }

  // Your NLP query can also live here!
  // This abstracts away the database-specific query logic.
  Future<int> getUnfinishedTaskCount() async {
    return await _database.countUnfinishedTasks();
  }
}
