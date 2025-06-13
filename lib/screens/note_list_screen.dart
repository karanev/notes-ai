import 'package:flutter/material.dart';
import '../repositories/note_repository.dart';
import '../services/database.dart'; // Needed to instantiate AppDatabase
import '../services/nlp_service.dart';
import '../models/note_status.dart';
import 'add_edit_note_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({Key? key}) : super(key: key);

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  // Instantiate the repository, which is the single source of truth for the UI.
  // We pass it a new database instance.
  // For a larger app, you would use a service locator (like get_it) or dependency injection.
  final NoteRepository _noteRepository = NoteRepository(AppDatabase());
  final NlpService _nlpService = NlpService(); // This service can also use the repository if needed.
  final TextEditingController _queryController = TextEditingController();

  void _askQuestion() async {
    if (_queryController.text.isEmpty) return;

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // The NLP service can use the repository to get data in a structured way
    final response = await _nlpService.processQueryWithRepository(_queryController.text, _noteRepository);

    Navigator.of(context).pop(); // Dismiss loading indicator

    // Show the result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Here's what I found:"),
        content: Text(response),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes AI'),
      ),
      body: Column(
        children: [
          // NLP Query Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Ask me a question...',
                hintText: 'e.g., how many finished tasks?',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _askQuestion,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _askQuestion(),
            ),
          ),
          // List of Notes (Reactive)
          Expanded(
            child: StreamBuilder<List<Note>>(
              // The UI listens to the repository's stream.
              stream: _noteRepository.watchAllNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notes yet. Tap the "+" to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          NoteStatus.displayText(note.status),
                          style: TextStyle(
                            color: NoteStatus.getColor(note.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // Navigate to the edit screen, passing the repository and the note.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditNoteScreen(
                                repository: _noteRepository,
                                note: note,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          // Show a confirmation dialog before deleting.
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Note?'),
                              content: Text('Are you sure you want to delete "${note.title}"?'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    _noteRepository.deleteNote(note.id);
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note deleted")));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add a new note, only passing the repository.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditNoteScreen(repository: _noteRepository),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}