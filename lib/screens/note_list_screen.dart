import 'package:flutter/material.dart';
import '../repositories/note_repository.dart';
import '../services/database.dart' show Note, NoteType;
import '../services/nlp_service/nlp_service.dart';
import '../services/nlp_service/nlp_models.dart'; // For NlpResult
import 'add_edit_note_screen.dart';
import 'dart:convert'; // For JSON decoding
import 'components/nlp_query_input.dart';
import 'components/notes_display.dart';
import 'components/nlp_result_dialog.dart'; // New component for the dialog
import 'components/delete_confirmation_dialog.dart'; // New component for delete confirmation

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

    // Use the new dialog component
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => NlpResultDialog(
        nlpResult: response,
        noteRepository: _noteRepository,
      ),
    );
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NaraNotes'),
      ),
      body: Column(
        children: [
          // NLP Query Input Area
          NlpQueryInput(
            controller: _queryController,
            onAskQuestion: _askQuestion,
          ),
          // List of Notes (Reactive)
          Expanded(
            child: NotesDisplay(
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
                  builder: (BuildContext dialogContext) => DeleteConfirmationDialog(
                    noteTitle: note.title,
                    onConfirmDelete: () {
                      _noteRepository.deleteNote(note.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note deleted")));
                    },
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
