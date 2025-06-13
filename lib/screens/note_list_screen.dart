import 'package:flutter/material.dart';
import '../repositories/note_repository.dart';
import '../services/database.dart' show Note, NoteType;
import '../services/nlp_service.dart';
import '../models/note_status.dart';
import 'add_edit_note_screen.dart';
import 'dart:convert'; // For JSON decoding

class NoteListScreen extends StatefulWidget {
  final NoteRepository noteRepository;
  final NlpService nlpService;

  const NoteListScreen({
    Key? key,
    required this.noteRepository,
    required this.nlpService,
  }) : super(key: key);

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final TextEditingController _queryController = TextEditingController();

  NoteRepository get _noteRepository => widget.noteRepository;
  NlpService get _nlpService => widget.nlpService;

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
          _NlpQueryInput(
            controller: _queryController,
            onAskQuestion: _askQuestion,
          ),
          // List of Notes (Reactive)
          Expanded(
            child: _NotesDisplay(
              noteRepository: _noteRepository,
              buildNoteSubtitle: _buildNoteSubtitle,
              onNoteTap: (note) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditNoteScreen(
                      repository: _noteRepository,
                      note: note,
                    ),
                  ),
                );
              },
              onNoteLongPress: (note) {
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
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteSubtitle(Note note) {
    if (note.noteType == NoteType.list) {
      try {
        final List<dynamic> decodedItemsJson = jsonDecode(note.content);
        List<Map<String, dynamic>> items = decodedItemsJson.map((item) {
          return {'text': item['text'] as String, 'isCompleted': item['isCompleted'] as bool? ?? false};
        }).toList();

        // Sort items: incomplete first, then completed
        items.sort((a, b) {
          if (a['isCompleted'] == b['isCompleted']) return 0;
          return (a['isCompleted'] as bool) ? 1 : -1;
        });

        if (items.isEmpty) {
          return const Text('[Empty list]', style: TextStyle(fontStyle: FontStyle.italic));
        }

        int completedCount = items.where((item) => item['isCompleted'] == true).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List ($completedCount/${items.length} completed)', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ...items.take(3).map((item) => Text(
                  '- ${item['text']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(decoration: item['isCompleted'] == true ? TextDecoration.lineThrough : null),
                )),
            if (items.length > 3) const Text('...', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        );
      } catch (e) {
        return const Text('[Error displaying list content]', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
      }
    }
    // Default for text notes
    return Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

class _NlpQueryInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAskQuestion;

  const _NlpQueryInput({
    required this.controller,
    required this.onAskQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Ask me a question...',
          hintText: 'e.g., how many finished tasks?',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: onAskQuestion,
          ),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onAskQuestion(),
      ),
    );
  }
}

class _NotesDisplay extends StatelessWidget {
  final NoteRepository noteRepository;
  final Widget Function(Note) buildNoteSubtitle;
  final void Function(Note) onNoteTap;
  final void Function(Note) onNoteLongPress;

  const _NotesDisplay({
    required this.noteRepository,
    required this.buildNoteSubtitle,
    required this.onNoteTap,
    required this.onNoteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: noteRepository.watchAllNotes(),
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
                subtitle: buildNoteSubtitle(note),
                trailing: Text(
                  NoteStatus.displayText(note.status),
                  style: TextStyle(
                    color: NoteStatus.getColor(note.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => onNoteTap(note),
                onLongPress: () => onNoteLongPress(note),
              ),
            );
          },
        );
      },
    );
  }
}